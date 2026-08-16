-------------------------------------------------------------------------------
-- Example: Lambert Intercept / Rendezvous Planning
-------------------------------------------------------------------------------
-- Demonstrates the Lambert solver for computing intercept trajectories.
-- Given a chaser spacecraft and target spacecraft, computes multiple
-- transfer options with varying time-of-flight.
--
-- This example shows:
--   1. Computing multiple Lambert solutions for different TOFs
--   2. Delta-V analysis for each option
--   3. Selecting optimal transfer based on fuel efficiency
--
-- Reference: Vallado, "Fundamentals of Astrodynamics", Chapter 5
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;   use Hale_Orbital.Vectors;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;
with Hale_Orbital.Lambert;   use Hale_Orbital.Lambert;
with Hale_Orbital.Kepler;    use Hale_Orbital.Kepler;

procedure Lambert_Intercept is

   package IO renames Ada.Text_IO;
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   ---------------------------------------------------------------------------
   -- Scenario: LEO Rendezvous
   ---------------------------------------------------------------------------
   --  Chaser spacecraft in 400 km circular orbit needs to intercept
   --  a target spacecraft in a similar orbit but at a different phase.

   --  Orbit parameters
   Orbit_Altitude : constant Distance_Km := 400.0;
   Orbit_Radius   : constant Distance_Km := R_Earth + Orbit_Altitude;

   --  Phase angle between chaser and target (target is ahead)
   Phase_Angle_Deg : constant := 30.0;
   Phase_Angle     : constant Real := Phase_Angle_Deg * Deg_To_Rad;

   --  Circular velocity at orbit altitude
   V_Circular : Velocity_Km_S;

   --  Number of transfer options to compute
   Num_Options : constant := 5;

   --  Transfer time range (0.25 to 1.25 orbital periods)
   Period : Time_Seconds;

   --  Results storage
   type Transfer_Option is record
      Tof      : Time_Seconds;
      Delta_V1 : Velocity_Km_S;
      Delta_V2 : Velocity_Km_S;
      Total_DV : Velocity_Km_S;
      A_Trans  : Distance_Km;
      E_Trans  : Real;
      Converged: Boolean;
   end record;

   Options : array (1 .. Num_Options) of Transfer_Option;
   Best_Option : Positive := 1;
   Min_DV : Velocity_Km_S := Velocity_Km_S'Last;

   ---------------------------------------------------------------------------
   -- Helper Procedures
   ---------------------------------------------------------------------------

   procedure Put_Real (Value : Real; Fore : Positive := 1; Aft : Positive := 3) is
      S : String (1 .. 20);
      package Real_IO is new Ada.Text_IO.Float_IO (Real);
   begin
      Real_IO.Put (S, Value, Aft => Aft, Exp => 0);
      IO.Put (S (1 .. Fore + Aft + 2));
   end Put_Real;

   procedure Print_Separator is
   begin
      IO.Put_Line ("============================================================");
   end Print_Separator;

begin
   Print_Separator;
   IO.Put_Line ("     LAMBERT INTERCEPT / RENDEZVOUS PLANNER");
   IO.Put_Line ("     HALE Orbital Mechanics Library - Ada 2012");
   Print_Separator;
   IO.New_Line;

   ---------------------------------------------------------------------------
   -- Compute orbital parameters
   ---------------------------------------------------------------------------

   V_Circular := Circular_Velocity (Orbit_Radius, Mu_Earth);
   Period := Orbital_Period (Orbit_Radius, Mu_Earth);

   IO.Put_Line ("SCENARIO: LEO Rendezvous");
   IO.Put_Line ("------------------------------------------------------------");
   IO.Put ("  Orbit altitude:     ");
   Put_Real (Real (Orbit_Altitude), Fore => 4, Aft => 1);
   IO.Put_Line (" km");

   IO.Put ("  Orbit radius:       ");
   Put_Real (Real (Orbit_Radius), Fore => 5, Aft => 1);
   IO.Put_Line (" km");

   IO.Put ("  Circular velocity:  ");
   Put_Real (Real (V_Circular), Fore => 2, Aft => 3);
   IO.Put_Line (" km/s");

   IO.Put ("  Orbital period:     ");
   Put_Real (Real (Period) / 60.0, Fore => 3, Aft => 1);
   IO.Put_Line (" minutes");

   IO.Put ("  Phase angle:        ");
   Put_Real (Phase_Angle_Deg, Fore => 2, Aft => 1);
   IO.Put_Line (" degrees (target ahead of chaser)");

   IO.New_Line;

   ---------------------------------------------------------------------------
   -- Define chaser and target positions
   ---------------------------------------------------------------------------

   IO.Put_Line ("COMPUTING TRANSFER OPTIONS");
   IO.Put_Line ("------------------------------------------------------------");
   IO.New_Line;

   --  Compute transfers for different times of flight
   for I in 1 .. Num_Options loop
      declare
         --  TOF ranges from 0.3 to 1.1 orbital periods
         Tof_Fraction : constant Real := 0.3 + Real (I - 1) * 0.2;
         Tof : constant Time_Seconds := Time_Seconds (Tof_Fraction * Real (Period));

         --  Chaser position (at time 0, on +X axis)
         R_Chaser : constant Position_Vector :=
            (Real (Orbit_Radius), 0.0, 0.0);
         V_Chaser : constant Velocity_Vector :=
            (0.0, Real (V_Circular), 0.0);

         --  Target position at time 0 (ahead by phase angle)
         Target_Angle_0 : constant Real := Phase_Angle;
         R_Target_0 : constant Position_Vector :=
            (Real (Orbit_Radius) * Cos (Target_Angle_0),
             Real (Orbit_Radius) * Sin (Target_Angle_0),
             0.0);

         --  Target position at arrival time (propagated)
         --  Angular rate = V / R
         Angular_Rate : constant Real := Real (V_Circular) / Real (Orbit_Radius);
         Target_Angle_Final : constant Real :=
            Target_Angle_0 + Angular_Rate * Real (Tof);
         R_Target_Final : constant Position_Vector :=
            (Real (Orbit_Radius) * Cos (Target_Angle_Final),
             Real (Orbit_Radius) * Sin (Target_Angle_Final),
             0.0);
         V_Target_Final : constant Velocity_Vector :=
            (-Real (V_Circular) * Sin (Target_Angle_Final),
              Real (V_Circular) * Cos (Target_Angle_Final),
             0.0);

         --  Solve Lambert problem
         Sol : Lambert_Result;

      begin
         Options (I).Tof := Tof;

         --  Solve Lambert
         Sol := Solve_Lambert (R_Chaser, R_Target_Final, Tof, Mu_Earth);

         if Sol.Converged then
            --  Compute delta-V
            Options (I).Delta_V1 := Velocity_Km_S (Magnitude (Sol.V1 - V_Chaser));
            Options (I).Delta_V2 := Velocity_Km_S (Magnitude (V_Target_Final - Sol.V2));
            Options (I).Total_DV := Velocity_Km_S (
               Real (Options (I).Delta_V1) + Real (Options (I).Delta_V2));
            Options (I).A_Trans := Sol.A;
            Options (I).E_Trans := Sol.E;
            Options (I).Converged := True;

            --  Track best option
            if Options (I).Total_DV < Min_DV then
               Min_DV := Options (I).Total_DV;
               Best_Option := I;
            end if;
         else
            Options (I).Converged := False;
         end if;
      end;
   end loop;

   ---------------------------------------------------------------------------
   -- Display results
   ---------------------------------------------------------------------------

   IO.Put_Line ("  Option   TOF (min)   DV1 (m/s)   DV2 (m/s)   Total (m/s)   a (km)      e");
   IO.Put_Line ("  ------   ---------   ---------   ---------   -----------   ------      -----");

   for I in 1 .. Num_Options loop
      IO.Put ("    ");
      IO.Put (Integer'Image (I));
      IO.Put ("       ");

      if Options (I).Converged then
         --  TOF in minutes
         Put_Real (Real (Options (I).Tof) / 60.0, Fore => 4, Aft => 1);
         IO.Put ("       ");

         --  Delta-V1 in m/s
         Put_Real (Real (Options (I).Delta_V1) * 1000.0, Fore => 4, Aft => 1);
         IO.Put ("       ");

         --  Delta-V2 in m/s
         Put_Real (Real (Options (I).Delta_V2) * 1000.0, Fore => 4, Aft => 1);
         IO.Put ("        ");

         --  Total in m/s
         Put_Real (Real (Options (I).Total_DV) * 1000.0, Fore => 5, Aft => 1);
         IO.Put ("     ");

         --  Semi-major axis
         Put_Real (Real (Options (I).A_Trans), Fore => 5, Aft => 0);
         IO.Put ("    ");

         --  Eccentricity
         Put_Real (Options (I).E_Trans, Fore => 1, Aft => 4);

         --  Mark best option
         if I = Best_Option then
            IO.Put ("  <-- OPTIMAL");
         end if;
      else
         IO.Put ("     (No solution found)");
      end if;

      IO.New_Line;
   end loop;

   IO.New_Line;

   ---------------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------------

   Print_Separator;
   IO.Put_Line ("                   RECOMMENDED TRANSFER");
   Print_Separator;
   IO.New_Line;

   if Options (Best_Option).Converged then
      IO.Put ("  Transfer time:      ");
      Put_Real (Real (Options (Best_Option).Tof) / 60.0, Fore => 4, Aft => 1);
      IO.Put_Line (" minutes");

      IO.Put ("  Departure burn:     ");
      Put_Real (Real (Options (Best_Option).Delta_V1) * 1000.0, Fore => 4, Aft => 1);
      IO.Put_Line (" m/s");

      IO.Put ("  Arrival burn:       ");
      Put_Real (Real (Options (Best_Option).Delta_V2) * 1000.0, Fore => 4, Aft => 1);
      IO.Put_Line (" m/s");

      IO.Put ("  Total delta-V:      ");
      Put_Real (Real (Options (Best_Option).Total_DV) * 1000.0, Fore => 4, Aft => 1);
      IO.Put_Line (" m/s");

      IO.New_Line;
      IO.Put_Line ("  Transfer orbit:");
      IO.Put ("    Semi-major axis:  ");
      Put_Real (Real (Options (Best_Option).A_Trans), Fore => 5, Aft => 1);
      IO.Put_Line (" km");

      IO.Put ("    Eccentricity:     ");
      Put_Real (Options (Best_Option).E_Trans, Fore => 1, Aft => 4);
      IO.New_Line;

      IO.New_Line;

      --  Fuel mass estimate (assuming Isp = 300s, 1000 kg spacecraft)
      declare
         Isp : constant := 300.0;  -- seconds
         M_Initial : constant := 1000.0;  -- kg
         G0 : constant := 9.80665e-3;  -- km/s^2
         Delta_V_Total : constant Real := Real (Options (Best_Option).Total_DV);
         Mass_Ratio : constant Real := Exp (Delta_V_Total / (Isp * G0));
         Fuel_Mass : constant Real := M_Initial * (1.0 - 1.0 / Mass_Ratio);
      begin
         IO.Put_Line ("  Fuel estimate (Isp=300s, M0=1000kg):");
         IO.Put ("    Fuel required:    ");
         Put_Real (Fuel_Mass, Fore => 3, Aft => 1);
         IO.Put_Line (" kg");
      end;
   else
      IO.Put_Line ("  ERROR: No valid transfer found!");
   end if;

   IO.New_Line;
   Print_Separator;

end Lambert_Intercept;
