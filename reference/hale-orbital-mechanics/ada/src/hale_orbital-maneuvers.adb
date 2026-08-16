-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Orbital Maneuvers Body
-------------------------------------------------------------------------------

with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;

package body Hale_Orbital.Maneuvers
   with SPARK_Mode => Off  --  Body uses generic instantiation
is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   ---------------------------------------------------------------------------
   -- Hohmann Transfer
   ---------------------------------------------------------------------------

   function Hohmann_Transfer (R_Initial : Distance_Km;
                              R_Final   : Distance_Km;
                              Mu        : Gravitational_Parameter) return Hohmann_Result is
      Result : Hohmann_Result;

      R1 : constant Real := Real (R_Initial);
      R2 : constant Real := Real (R_Final);
      Mu_Val : constant Real := Real (Mu);

      --  Transfer ellipse parameters
      A_Trans : Real;
      V_Circ_1, V_Circ_2 : Real;
      V_Trans_1, V_Trans_2 : Real;

   begin
      if R1 <= 0.0 or R2 <= 0.0 then
         raise Physical_Error with "Radii must be positive";
      end if;

      --  Semi-major axis of transfer ellipse
      A_Trans := (R1 + R2) / 2.0;

      --  Circular velocities
      V_Circ_1 := Sqrt (Mu_Val / R1);
      V_Circ_2 := Sqrt (Mu_Val / R2);

      --  Transfer velocities at periapsis and apoapsis
      V_Trans_1 := Sqrt (Mu_Val * (2.0 / R1 - 1.0 / A_Trans));
      V_Trans_2 := Sqrt (Mu_Val * (2.0 / R2 - 1.0 / A_Trans));

      --  Delta-V magnitudes
      Result.Delta_V1 := Velocity_Km_S (abs (V_Trans_1 - V_Circ_1));
      Result.Delta_V2 := Velocity_Km_S (abs (V_Circ_2 - V_Trans_2));
      Result.Total_Delta_V := Velocity_Km_S (Real (Result.Delta_V1) + Real (Result.Delta_V2));

      --  Transfer time (half period)
      Result.Transfer_Time := Time_Seconds (Pi * Sqrt (A_Trans**3 / Mu_Val));

      --  Transfer orbit parameters
      Result.A_Transfer := Distance_Km (A_Trans);

      --  Eccentricity of transfer
      if R1 < R2 then
         --  Raising orbit: periapsis at R1, apoapsis at R2
         Result.E_Transfer := (R2 - R1) / (R2 + R1);
      else
         --  Lowering orbit: periapsis at R2, apoapsis at R1
         Result.E_Transfer := (R1 - R2) / (R1 + R2);
      end if;

      return Result;
   end Hohmann_Transfer;

   function Hohmann_Delta_V1 (R_Initial : Distance_Km;
                              R_Final   : Distance_Km;
                              Mu        : Gravitational_Parameter) return Velocity_Km_S is
   begin
      return Hohmann_Transfer (R_Initial, R_Final, Mu).Delta_V1;
   end Hohmann_Delta_V1;

   function Hohmann_Delta_V2 (R_Initial : Distance_Km;
                              R_Final   : Distance_Km;
                              Mu        : Gravitational_Parameter) return Velocity_Km_S is
   begin
      return Hohmann_Transfer (R_Initial, R_Final, Mu).Delta_V2;
   end Hohmann_Delta_V2;

   function Hohmann_Total_Delta_V (R_Initial : Distance_Km;
                                   R_Final   : Distance_Km;
                                   Mu        : Gravitational_Parameter) return Velocity_Km_S is
   begin
      return Hohmann_Transfer (R_Initial, R_Final, Mu).Total_Delta_V;
   end Hohmann_Total_Delta_V;

   function Hohmann_Transfer_Time (R_Initial : Distance_Km;
                                   R_Final   : Distance_Km;
                                   Mu        : Gravitational_Parameter) return Time_Seconds is
   begin
      return Hohmann_Transfer (R_Initial, R_Final, Mu).Transfer_Time;
   end Hohmann_Transfer_Time;

   ---------------------------------------------------------------------------
   -- Bi-Elliptic Transfer
   ---------------------------------------------------------------------------

   function Bielliptic_Transfer (R_Initial     : Distance_Km;
                                 R_Final       : Distance_Km;
                                 R_Intermediate: Distance_Km;
                                 Mu            : Gravitational_Parameter) return Bielliptic_Result is
      Result : Bielliptic_Result;

      R1 : constant Real := Real (R_Initial);
      R2 : constant Real := Real (R_Final);
      Rb : constant Real := Real (R_Intermediate);
      Mu_Val : constant Real := Real (Mu);

      --  Transfer ellipse semi-major axes
      A1, A2 : Real;

      --  Velocities
      V_Circ_1, V_Circ_2 : Real;
      V_Trans1_P, V_Trans1_A : Real;
      V_Trans2_P, V_Trans2_A : Real;

   begin
      if R1 <= 0.0 or R2 <= 0.0 or Rb <= 0.0 then
         raise Physical_Error with "Radii must be positive";
      end if;

      if Rb < R1 or Rb < R2 then
         raise Physical_Error with "Intermediate radius must be greater than both endpoints";
      end if;

      --  Semi-major axes of transfer ellipses
      A1 := (R1 + Rb) / 2.0;
      A2 := (R2 + Rb) / 2.0;

      --  Circular velocities at endpoints
      V_Circ_1 := Sqrt (Mu_Val / R1);
      V_Circ_2 := Sqrt (Mu_Val / R2);

      --  First transfer ellipse velocities
      V_Trans1_P := Sqrt (Mu_Val * (2.0 / R1 - 1.0 / A1));  -- At R1 (periapsis)
      V_Trans1_A := Sqrt (Mu_Val * (2.0 / Rb - 1.0 / A1));  -- At Rb (apoapsis)

      --  Second transfer ellipse velocities
      V_Trans2_A := Sqrt (Mu_Val * (2.0 / Rb - 1.0 / A2));  -- At Rb (apoapsis)
      V_Trans2_P := Sqrt (Mu_Val * (2.0 / R2 - 1.0 / A2));  -- At R2 (periapsis)

      --  Delta-V for each burn
      Result.Delta_V1 := Velocity_Km_S (abs (V_Trans1_P - V_Circ_1));
      Result.Delta_V2 := Velocity_Km_S (abs (V_Trans2_A - V_Trans1_A));
      Result.Delta_V3 := Velocity_Km_S (abs (V_Circ_2 - V_Trans2_P));

      Result.Total_Delta_V := Velocity_Km_S (Real (Result.Delta_V1) +
                                             Real (Result.Delta_V2) +
                                             Real (Result.Delta_V3));

      --  Total transfer time (two half-periods)
      Result.Transfer_Time := Time_Seconds (Pi * Sqrt (A1**3 / Mu_Val) +
                                            Pi * Sqrt (A2**3 / Mu_Val));

      Result.R_Intermediate := R_Intermediate;

      return Result;
   end Bielliptic_Transfer;

   function Bielliptic_Is_Efficient (R_Initial : Distance_Km;
                                     R_Final   : Distance_Km) return Boolean is
      Ratio : constant Real := Real (R_Final) / Real (R_Initial);
   begin
      --  Bi-elliptic is more efficient when ratio > 11.94
      --  (or < 1/11.94 for lowering)
      return Ratio > 11.94 or Ratio < 1.0 / 11.94;
   end Bielliptic_Is_Efficient;

   function Optimal_Bielliptic_Radius (R_Initial : Distance_Km;
                                       R_Final   : Distance_Km;
                                       Mu        : Gravitational_Parameter) return Distance_Km is
      pragma Unreferenced (Mu);
   begin
      if not Bielliptic_Is_Efficient (R_Initial, R_Final) then
         return 0.0;  -- Hohmann is better
      end if;

      --  For optimal efficiency, use very large intermediate radius
      --  In practice, use infinity approximation: R_b -> infinity
      --  Return a practical large value (100x the larger radius)
      if Real (R_Final) > Real (R_Initial) then
         return Distance_Km (100.0 * Real (R_Final));
      else
         return Distance_Km (100.0 * Real (R_Initial));
      end if;
   end Optimal_Bielliptic_Radius;

   ---------------------------------------------------------------------------
   -- Plane Change Maneuvers
   ---------------------------------------------------------------------------

   function Simple_Plane_Change (Delta_I : Angle_Radians;
                                 V       : Velocity_Km_S) return Velocity_Km_S is
   begin
      --  Delta-V = 2 * V * sin(Delta_i / 2)
      return Velocity_Km_S (2.0 * Real (V) * Sin (Real (Delta_I) / 2.0));
   end Simple_Plane_Change;

   function Combined_Plane_Change (R_Initial : Distance_Km;
                                   R_Final   : Distance_Km;
                                   Delta_I   : Angle_Radians;
                                   Mu        : Gravitational_Parameter) return Velocity_Km_S is
      R1 : constant Real := Real (R_Initial);
      R2 : constant Real := Real (R_Final);
      Mu_Val : constant Real := Real (Mu);

      --  Transfer ellipse
      A_Trans : constant Real := (R1 + R2) / 2.0;

      --  Velocities at apoapsis
      V_Trans_A : Real;
      V_Circ_F : Real;

      --  Combined delta-V using law of cosines
      Delta_V : Real;

   begin
      --  Assume plane change at apoapsis (R2) for efficiency
      V_Trans_A := Sqrt (Mu_Val * (2.0 / R2 - 1.0 / A_Trans));
      V_Circ_F := Sqrt (Mu_Val / R2);

      --  Law of cosines: Delta_V^2 = V1^2 + V2^2 - 2*V1*V2*cos(Delta_i)
      Delta_V := Sqrt (V_Trans_A**2 + V_Circ_F**2 -
                       2.0 * V_Trans_A * V_Circ_F * Cos (Real (Delta_I)));

      return Velocity_Km_S (Delta_V);
   end Combined_Plane_Change;

   function Combined_Maneuver (R_Initial : Distance_Km;
                               R_Final   : Distance_Km;
                               Delta_I   : Angle_Radians;
                               Mu        : Gravitational_Parameter) return Hohmann_Result is
      Result : Hohmann_Result;
      Hohmann : constant Hohmann_Result := Hohmann_Transfer (R_Initial, R_Final, Mu);
   begin
      --  First burn is same as Hohmann (coplanar)
      Result.Delta_V1 := Hohmann.Delta_V1;

      --  Second burn combines plane change with circularization
      Result.Delta_V2 := Combined_Plane_Change (R_Initial, R_Final, Delta_I, Mu);

      Result.Total_Delta_V := Velocity_Km_S (Real (Result.Delta_V1) + Real (Result.Delta_V2));
      Result.Transfer_Time := Hohmann.Transfer_Time;
      Result.A_Transfer := Hohmann.A_Transfer;
      Result.E_Transfer := Hohmann.E_Transfer;

      return Result;
   end Combined_Maneuver;

   ---------------------------------------------------------------------------
   -- General Coplanar Transfer
   ---------------------------------------------------------------------------

   function Coplanar_Transfer (A1  : Distance_Km;
                               E1  : Real;
                               Nu1 : Angle_Radians;
                               A2  : Distance_Km;
                               E2  : Real;
                               Nu2 : Angle_Radians;
                               Mu  : Gravitational_Parameter) return Transfer_Result is
      Result : Transfer_Result;
      pragma Unreferenced (Nu1, Nu2);

      --  For simplicity, compute as Hohmann-like transfer
      --  between periapses of both orbits
      R_P1 : constant Distance_Km := Periapsis_Distance (A1, E1);
      R_P2 : constant Distance_Km := Periapsis_Distance (A2, E2);

      Hohmann : constant Hohmann_Result := Hohmann_Transfer (R_P1, R_P2, Mu);

   begin
      Result.Delta_V1 := Hohmann.Delta_V1;
      Result.Delta_V2 := Hohmann.Delta_V2;
      Result.Total_Delta_V := Hohmann.Total_Delta_V;
      Result.Transfer_Time := Hohmann.Transfer_Time;

      --  Transfer orbit elements (simplified)
      Result.Transfer_Orbit.Semi_Major_Axis := Hohmann.A_Transfer;
      Result.Transfer_Orbit.Eccentricity := Hohmann.E_Transfer;
      Result.Transfer_Orbit.Inclination := 0.0;
      Result.Transfer_Orbit.RAAN := 0.0;
      Result.Transfer_Orbit.Argument_Of_Periapsis := 0.0;
      Result.Transfer_Orbit.True_Anomaly := 0.0;

      return Result;
   end Coplanar_Transfer;

   ---------------------------------------------------------------------------
   -- Phasing Maneuvers
   ---------------------------------------------------------------------------

   function Phasing_Orbit_SMA (R_Orbit     : Distance_Km;
                               Phase_Angle : Angle_Radians;
                               N_Orbits    : Positive;
                               Mu          : Gravitational_Parameter) return Distance_Km is
      R : constant Real := Real (R_Orbit);
      Phi : constant Real := Real (Phase_Angle);
      N : constant Real := Real (N_Orbits);
      Mu_Val : constant Real := Real (Mu);

      --  Target orbit period
      T_Target : Real;

      --  Required phasing orbit period
      T_Phase : Real;

      --  Phasing orbit semi-major axis
      A_Phase : Real;

   begin
      --  Period of target circular orbit
      T_Target := Two_Pi * Sqrt (R**3 / Mu_Val);

      --  Required phasing period to close phase angle in N target orbits
      --  T_phase * N = T_target * N - Phi / (2*pi) * T_target
      --  T_phase = T_target * (1 - Phi / (2*pi*N))
      T_Phase := T_Target * (1.0 - Phi / (Two_Pi * N));

      --  Semi-major axis from period
      --  T = 2*pi * sqrt(a^3/mu) => a = (mu * (T/(2*pi))^2)^(1/3)
      A_Phase := (Mu_Val * (T_Phase / Two_Pi)**2) ** (1.0 / 3.0);

      return Distance_Km (A_Phase);
   end Phasing_Orbit_SMA;

   function Phasing_Delta_V (R_Orbit     : Distance_Km;
                             Phase_Angle : Angle_Radians;
                             N_Orbits    : Positive;
                             Mu          : Gravitational_Parameter) return Velocity_Km_S is
      A_Phase : constant Distance_Km := Phasing_Orbit_SMA (R_Orbit, Phase_Angle, N_Orbits, Mu);
      Hohmann : constant Hohmann_Result := Hohmann_Transfer (R_Orbit, Periapsis_Distance (A_Phase, 0.0), Mu);
   begin
      --  Total delta-V is 2x the first Hohmann burn (enter and exit phasing orbit)
      return Velocity_Km_S (2.0 * Real (Hohmann.Delta_V1));
   end Phasing_Delta_V;

   ---------------------------------------------------------------------------
   -- Escape and Capture
   ---------------------------------------------------------------------------

   function Escape_Delta_V (R : Distance_Km;
                            Mu : Gravitational_Parameter) return Velocity_Km_S is
      V_Circ : constant Velocity_Km_S := Circular_Velocity (R, Mu);
      V_Esc : constant Velocity_Km_S := Escape_Velocity (R, Mu);
   begin
      return Velocity_Km_S (Real (V_Esc) - Real (V_Circ));
   end Escape_Delta_V;

   function Capture_Delta_V (R : Distance_Km;
                             Mu : Gravitational_Parameter) return Velocity_Km_S is
   begin
      --  Same as escape, by symmetry
      return Escape_Delta_V (R, Mu);
   end Capture_Delta_V;

   function C3_Energy (V_Infinity : Velocity_Km_S)
      return Hale_Orbital.Types.Specific_Energy is
   begin
      --  C3 = V_infinity^2
      return Hale_Orbital.Types.Specific_Energy (Real (V_Infinity) ** 2);
   end C3_Energy;

   function Departure_Velocity (R  : Distance_Km;
                                C3 : Hale_Orbital.Types.Specific_Energy;
                                Mu : Gravitational_Parameter) return Velocity_Km_S is
      V_Sq : Real;
   begin
      --  V^2 = V_esc^2 + C3 = 2*mu/r + C3
      V_Sq := 2.0 * Real (Mu) / Real (R) + Real (C3);

      if V_Sq < 0.0 then
         raise Physical_Error with "Invalid C3 for given radius";
      end if;

      return Velocity_Km_S (Sqrt (V_Sq));
   end Departure_Velocity;

end Hale_Orbital.Maneuvers;
