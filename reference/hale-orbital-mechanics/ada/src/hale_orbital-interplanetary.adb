-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Interplanetary Trajectories Package Body
-------------------------------------------------------------------------------

with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;
with Hale_Orbital.Maneuvers; use Hale_Orbital.Maneuvers;

package body Hale_Orbital.Interplanetary
   with SPARK_Mode => Off  -- Uses generic instantiation
is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   ---------------------------------------------------------------------------
   -- Planetary Data Access
   ---------------------------------------------------------------------------

   function Get_Planet_Data (Planet : Planet_Type) return Planet_Data is
   begin
      case Planet is
         when Mercury => return Mercury_Data;
         when Venus   => return Venus_Data;
         when Earth   => return Earth_Data;
         when Mars    => return Mars_Data;
         when Jupiter => return Jupiter_Data;
         when Saturn  => return Saturn_Data;
         when Uranus  => return Uranus_Data;
         when Neptune => return Neptune_Data;
      end case;
   end Get_Planet_Data;

   ---------------------------------------------------------------------------
   -- Sphere of Influence
   ---------------------------------------------------------------------------

   function Sphere_Of_Influence (A_Planet : Distance_Km;
                                  Mu_Planet : Gravitational_Parameter;
                                  Mu_Star   : Gravitational_Parameter := Mu_Sun) return Distance_Km is
      --  Laplace formula: r_SOI = a * (m_planet / m_sun)^(2/5)
      --  Since mu = G*m, the mass ratio equals mu ratio
      Mass_Ratio : constant Real := Real (Mu_Planet) / Real (Mu_Star);
      Exponent : constant Real := 0.4;  -- 2/5
   begin
      return Distance_Km (Real (A_Planet) * (Mass_Ratio ** Exponent));
   end Sphere_Of_Influence;

   function Within_SOI (R_From_Planet : Distance_Km;
                        Planet        : Planet_Type) return Boolean is
      Data : constant Planet_Data := Get_Planet_Data (Planet);
   begin
      return Real (R_From_Planet) <= Real (Data.SOI_Radius);
   end Within_SOI;

   ---------------------------------------------------------------------------
   -- Hyperbolic Trajectory Parameters
   ---------------------------------------------------------------------------

   function Hyperbolic_Excess_Velocity (V_Total  : Velocity_Km_S;
                                        R        : Distance_Km;
                                        Mu       : Gravitational_Parameter) return Velocity_Km_S is
      V_Squared : constant Real := Real (V_Total) ** 2;
      V_Esc_Squared : constant Real := 2.0 * Real (Mu) / Real (R);
      V_Inf_Squared : constant Real := V_Squared - V_Esc_Squared;
   begin
      if V_Inf_Squared > 0.0 then
         return Velocity_Km_S (Sqrt (V_Inf_Squared));
      else
         return 0.0;
      end if;
   end Hyperbolic_Excess_Velocity;

   function V_Infinity_From_C3 (C3 : Hale_Orbital.Types.Specific_Energy) return Velocity_Km_S is
   begin
      --  C3 = V_inf^2, so V_inf = sqrt(C3)
      if Real (C3) >= 0.0 then
         return Velocity_Km_S (Sqrt (Real (C3)));
      else
         return 0.0;
      end if;
   end V_Infinity_From_C3;

   function C3_From_V_Infinity (V_Inf : Velocity_Km_S) return Hale_Orbital.Types.Specific_Energy is
   begin
      return Hale_Orbital.Types.Specific_Energy (Real (V_Inf) ** 2);
   end C3_From_V_Infinity;

   function Hyperbolic_Periapsis_Velocity (V_Infinity  : Velocity_Km_S;
                                           R_Periapsis : Distance_Km;
                                           Mu          : Gravitational_Parameter) return Velocity_Km_S is
      --  At periapsis: V_p^2 = V_inf^2 + 2*mu/r_p
      V_Inf_Sq : constant Real := Real (V_Infinity) ** 2;
      V_Esc_Sq : constant Real := 2.0 * Real (Mu) / Real (R_Periapsis);
   begin
      return Velocity_Km_S (Sqrt (V_Inf_Sq + V_Esc_Sq));
   end Hyperbolic_Periapsis_Velocity;

   function Hyperbolic_Semi_Major_Axis (V_Infinity : Velocity_Km_S;
                                        Mu         : Gravitational_Parameter) return Distance_Km is
      --  For hyperbola: a = -mu / V_inf^2  (negative)
      V_Inf_Sq : constant Real := Real (V_Infinity) ** 2;
   begin
      if V_Inf_Sq > 0.0 then
         return Distance_Km (-Real (Mu) / V_Inf_Sq);
      else
         return 0.0;
      end if;
   end Hyperbolic_Semi_Major_Axis;

   function Hyperbolic_Eccentricity (V_Infinity  : Velocity_Km_S;
                                     R_Periapsis : Distance_Km;
                                     Mu          : Gravitational_Parameter) return Real is
      --  e = 1 + r_p * V_inf^2 / mu
      V_Inf_Sq : constant Real := Real (V_Infinity) ** 2;
   begin
      return 1.0 + Real (R_Periapsis) * V_Inf_Sq / Real (Mu);
   end Hyperbolic_Eccentricity;

   function Turn_Angle (V_Infinity  : Velocity_Km_S;
                        R_Periapsis : Distance_Km;
                        Mu          : Gravitational_Parameter) return Angle_Radians is
      --  Turn angle delta = 2 * arcsin(1/e)
      E : constant Real := Hyperbolic_Eccentricity (V_Infinity, R_Periapsis, Mu);
   begin
      if E > 1.0 then
         return Angle_Radians (2.0 * Arcsin (1.0 / E));
      else
         return 0.0;
      end if;
   end Turn_Angle;

   ---------------------------------------------------------------------------
   -- Patched Conic Transfer
   ---------------------------------------------------------------------------

   function Compute_Patched_Conic (Departure_Planet  : Planet_Type;
                                    Arrival_Planet    : Planet_Type;
                                    Time_Of_Flight    : Time_Seconds;
                                    Parking_Altitude  : Distance_Km;
                                    Capture_Altitude  : Distance_Km) return Patched_Conic_Result is
      Result : Patched_Conic_Result;
      Dep_Data : constant Planet_Data := Get_Planet_Data (Departure_Planet);
      Arr_Data : constant Planet_Data := Get_Planet_Data (Arrival_Planet);

      --  Heliocentric distances (using semi-major axes as approximation)
      R1 : constant Distance_Km := Dep_Data.Semi_Major_Axis;
      R2 : constant Distance_Km := Arr_Data.Semi_Major_Axis;

      --  Transfer orbit parameters
      A_Transfer : constant Real := (Real (R1) + Real (R2)) / 2.0;
      E_Transfer : constant Real := abs (Real (R2) - Real (R1)) / (Real (R1) + Real (R2));

      --  Heliocentric velocities at departure and arrival
      V_Helio_Dep : constant Real := Sqrt (Real (Mu_Sun) * (2.0 / Real (R1) - 1.0 / A_Transfer));
      V_Helio_Arr : constant Real := Sqrt (Real (Mu_Sun) * (2.0 / Real (R2) - 1.0 / A_Transfer));

      --  Planetary orbital velocities (circular approximation)
      V_Planet_Dep : constant Real := Sqrt (Real (Mu_Sun) / Real (R1));
      V_Planet_Arr : constant Real := Sqrt (Real (Mu_Sun) / Real (R2));

      --  Excess velocities relative to planets
      V_Inf_Dep : Real;
      V_Inf_Arr : Real;

      --  Parking and capture orbit parameters
      R_Park : constant Distance_Km := Distance_Km (Real (Dep_Data.Radius) + Real (Parking_Altitude));
      R_Capt : constant Distance_Km := Distance_Km (Real (Arr_Data.Radius) + Real (Capture_Altitude));

      V_Park_Circ : constant Real := Real (Circular_Velocity (R_Park, Dep_Data.Mu));
      V_Capt_Circ : constant Real := Real (Circular_Velocity (R_Capt, Arr_Data.Mu));

      V_Hyp_Dep : Real;
      V_Hyp_Arr : Real;

   begin
      --  Determine transfer direction
      if Real (R2) > Real (R1) then
         --  Outbound transfer (e.g., Earth to Mars)
         V_Inf_Dep := V_Helio_Dep - V_Planet_Dep;
         V_Inf_Arr := V_Planet_Arr - V_Helio_Arr;
      else
         --  Inbound transfer (e.g., Mars to Earth)
         V_Inf_Dep := V_Planet_Dep - V_Helio_Dep;
         V_Inf_Arr := V_Helio_Arr - V_Planet_Arr;
      end if;

      --  Ensure positive excess velocities
      V_Inf_Dep := abs (V_Inf_Dep);
      V_Inf_Arr := abs (V_Inf_Arr);

      --  Departure hyperbola velocity at periapsis
      V_Hyp_Dep := Real (Hyperbolic_Periapsis_Velocity (Velocity_Km_S (V_Inf_Dep), R_Park, Dep_Data.Mu));

      --  Arrival hyperbola velocity at periapsis
      V_Hyp_Arr := Real (Hyperbolic_Periapsis_Velocity (Velocity_Km_S (V_Inf_Arr), R_Capt, Arr_Data.Mu));

      --  Fill result
      Result.Departure_V_Inf := Velocity_Km_S (V_Inf_Dep);
      Result.Departure_C3 := C3_From_V_Infinity (Result.Departure_V_Inf);
      Result.Departure_DV := Velocity_Km_S (abs (V_Hyp_Dep - V_Park_Circ));

      Result.Transfer_TOF := Time_Of_Flight;
      Result.Transfer_SMA := Distance_Km (A_Transfer);
      Result.Transfer_Ecc := E_Transfer;

      Result.Arrival_V_Inf := Velocity_Km_S (V_Inf_Arr);
      Result.Arrival_C3 := C3_From_V_Infinity (Result.Arrival_V_Inf);
      Result.Capture_DV := Velocity_Km_S (abs (V_Hyp_Arr - V_Capt_Circ));

      Result.Total_DV := Velocity_Km_S (Real (Result.Departure_DV) + Real (Result.Capture_DV));
      Result.Valid := True;

      return Result;
   end Compute_Patched_Conic;

   function Hohmann_Interplanetary (Departure_Planet : Planet_Type;
                                    Arrival_Planet   : Planet_Type) return Patched_Conic_Result is
      Dep_Data : constant Planet_Data := Get_Planet_Data (Departure_Planet);
      Arr_Data : constant Planet_Data := Get_Planet_Data (Arrival_Planet);

      --  Transfer orbit semi-major axis
      A_Transfer : constant Real := (Real (Dep_Data.Semi_Major_Axis) +
                                     Real (Arr_Data.Semi_Major_Axis)) / 2.0;

      --  Hohmann TOF = half the transfer orbit period
      TOF : constant Time_Seconds := Time_Seconds (Pi * Sqrt (A_Transfer ** 3 / Real (Mu_Sun)));

      --  Default parking/capture altitudes
      Park_Alt : constant Distance_Km := 300.0;
      Capt_Alt : constant Distance_Km := 300.0;

   begin
      return Compute_Patched_Conic (Departure_Planet, Arrival_Planet, TOF, Park_Alt, Capt_Alt);
   end Hohmann_Interplanetary;

   ---------------------------------------------------------------------------
   -- Gravity Assist (Flyby)
   ---------------------------------------------------------------------------

   function Compute_Flyby (V_Infinity_In : Velocity_Km_S;
                           R_Periapsis   : Distance_Km;
                           Planet        : Planet_Type) return Flyby_Result is
      Result : Flyby_Result;
      Data : constant Planet_Data := Get_Planet_Data (Planet);

      --  Turn angle
      Delta_Val : constant Angle_Radians := Turn_Angle (V_Infinity_In, R_Periapsis, Data.Mu);

      --  Delta_Val-V gain = 2 * V_inf * sin(delta/2)
      Delta_V : constant Real := 2.0 * Real (V_Infinity_In) * Sin (Real (Delta_Val) / 2.0);

   begin
      Result.Turn_Angle := Delta_Val;
      Result.Delta_V_Gain := Velocity_Km_S (Delta_V);
      Result.Exit_V_Inf := V_Infinity_In;  -- Magnitude unchanged
      Result.R_Periapsis := R_Periapsis;

      --  Check if flyby is valid (above surface with margin)
      Result.Valid := Real (R_Periapsis) > Real (Data.Radius) + 100.0;

      return Result;
   end Compute_Flyby;

   function Minimum_Flyby_Radius (Planet : Planet_Type;
                                   Altitude : Distance_Km := 200.0) return Distance_Km is
      Data : constant Planet_Data := Get_Planet_Data (Planet);
   begin
      return Distance_Km (Real (Data.Radius) + Real (Altitude));
   end Minimum_Flyby_Radius;

   function Maximum_Flyby_DeltaV (V_Infinity : Velocity_Km_S;
                                   Planet     : Planet_Type) return Velocity_Km_S is
      --  Maximum turn is 180 degrees (impossible but theoretical limit)
      --  Practical maximum uses minimum flyby radius
      R_Min : constant Distance_Km := Minimum_Flyby_Radius (Planet);
      Flyby : constant Flyby_Result := Compute_Flyby (V_Infinity, R_Min, Planet);
   begin
      return Flyby.Delta_V_Gain;
   end Maximum_Flyby_DeltaV;

   ---------------------------------------------------------------------------
   -- Synodic Period and Launch Windows
   ---------------------------------------------------------------------------

   function Synodic_Period (Inner_Planet : Planet_Type;
                            Outer_Planet : Planet_Type) return Time_Seconds is
      Inner_Data : constant Planet_Data := Get_Planet_Data (Inner_Planet);
      Outer_Data : constant Planet_Data := Get_Planet_Data (Outer_Planet);

      --  Orbital periods
      T_Inner : constant Real := Two_Pi * Sqrt (Real (Inner_Data.Semi_Major_Axis) ** 3 / Real (Mu_Sun));
      T_Outer : constant Real := Two_Pi * Sqrt (Real (Outer_Data.Semi_Major_Axis) ** 3 / Real (Mu_Sun));

      --  Synodic period: 1/T_syn = |1/T_inner - 1/T_outer|
      Synodic : constant Real := 1.0 / abs (1.0 / T_Inner - 1.0 / T_Outer);

   begin
      return Time_Seconds (Synodic);
   end Synodic_Period;

   function Hohmann_Phase_Angle (Departure_Planet : Planet_Type;
                                  Arrival_Planet   : Planet_Type) return Angle_Radians is
      Dep_Data : constant Planet_Data := Get_Planet_Data (Departure_Planet);
      Arr_Data : constant Planet_Data := Get_Planet_Data (Arrival_Planet);

      --  Transfer semi-major axis
      A_Transfer : constant Real := (Real (Dep_Data.Semi_Major_Axis) +
                                     Real (Arr_Data.Semi_Major_Axis)) / 2.0;

      --  Transfer time (half period)
      TOF : constant Real := Pi * Sqrt (A_Transfer ** 3 / Real (Mu_Sun));

      --  Angular velocity of arrival planet
      N_Arr : constant Real := Sqrt (Real (Mu_Sun) / Real (Arr_Data.Semi_Major_Axis) ** 3);

      --  Angle traversed by arrival planet during transfer
      Theta_Arr : constant Real := N_Arr * TOF;

      --  Required phase angle (lead angle for outer, lag for inner)
      Phase : Real;

   begin
      if Real (Arr_Data.Semi_Major_Axis) > Real (Dep_Data.Semi_Major_Axis) then
         --  Outbound: arrival planet should be ahead by (Pi - Theta_Arr)
         Phase := Pi - Theta_Arr;
      else
         --  Inbound: departure planet should be behind
         Phase := Pi - Theta_Arr;
      end if;

      --  Normalize to [0, 2*Pi)
      while Phase < 0.0 loop
         Phase := Phase + Two_Pi;
      end loop;
      while Phase >= Two_Pi loop
         Phase := Phase - Two_Pi;
      end loop;

      return Angle_Radians (Phase);
   end Hohmann_Phase_Angle;

end Hale_Orbital.Interplanetary;
