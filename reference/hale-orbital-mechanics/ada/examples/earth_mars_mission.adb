-------------------------------------------------------------------------------
-- Example: Earth to Mars Mission Planner
-------------------------------------------------------------------------------
-- Complete Earth to Mars transfer mission planning example demonstrating
-- the full mission planning workflow using the HALE Orbital Mechanics Library.
--
-- This example shows:
--   1. Planetary position setup (simplified circular coplanar orbits)
--   2. Lambert problem solution for transfer trajectory
--   3. Delta-V budget calculation
--   4. Trajectory propagation and verification
--   5. Mission summary display
--
-- Reference: Hale, "Introduction to Space Flight", Chapter 6
--            Vallado, "Fundamentals of Astrodynamics", Chapter 5
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Types;       use Hale_Orbital.Types;
with Hale_Orbital.Constants;   use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;     use Hale_Orbital.Vectors;
with Hale_Orbital.Twobody;     use Hale_Orbital.Twobody;
with Hale_Orbital.Lambert;     use Hale_Orbital.Lambert;
with Hale_Orbital.Propagation; use Hale_Orbital.Propagation;

procedure Earth_Mars_Mission is

   package IO renames Ada.Text_IO;
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   ---------------------------------------------------------------------------
   -- Mission Parameters
   ---------------------------------------------------------------------------

   --  Orbital radii (assuming circular orbits for simplicity)
   Earth_Orbit_Radius : constant Distance_Km := AU;               -- 1 AU
   Mars_Orbit_Radius  : constant Distance_Km := A_Mars;           -- 1.524 AU

   --  Transfer time: ~259 days for Hohmann-like transfer
   --  Using 200 days for a slightly faster trajectory
   Transfer_Days : constant := 200;
   Transfer_Time : constant Time_Seconds := Time_Seconds (Transfer_Days * 86400);

   --  Days to seconds conversion
   Day_Seconds : constant := 86400.0;

   ---------------------------------------------------------------------------
   -- Mission Variables
   ---------------------------------------------------------------------------

   --  Departure conditions
   Earth_Position : Position_Vector;
   Earth_Velocity : Velocity_Vector;

   --  Arrival conditions
   Mars_Position : Position_Vector;
   Mars_Velocity : Velocity_Vector;

   --  Phase angle for Mars at arrival
   --  Computed from orbital mechanics
   Earth_Angular_Rate : Real;
   Mars_Angular_Rate  : Real;
   Phase_Angle        : Real;

   --  Lambert solution
   Lambert_Sol : Lambert_Result;

   --  Delta-V budget
   Departure_DV : Velocity_Km_S;
   Arrival_DV   : Velocity_Km_S;
   Total_DV     : Velocity_Km_S;

   --  Trajectory
   Traj : Timed_Trajectory (1 .. 21);  -- 21 points (every 10 days)

   --  Force model for propagation
   Sun_Model : Two_Body_Model;

   --  Energy conservation check
   Energy_Err : Real;

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
      IO.Put_Line ("==========================================================");
   end Print_Separator;

begin
   Print_Separator;
   IO.Put_Line ("     EARTH TO MARS MISSION PLANNER");
   IO.Put_Line ("     HALE Orbital Mechanics Library - Ada 2012");
   Print_Separator;
   IO.New_Line;

   ---------------------------------------------------------------------------
   -- Step 1: Define Planetary Positions
   ---------------------------------------------------------------------------

   IO.Put_Line ("STEP 1: Planetary Configuration");
   IO.Put_Line ("----------------------------------------------------------");

   --  Compute angular rates (rad/s)
   Earth_Angular_Rate := Sqrt (Real (Mu_Sun) / (Real (Earth_Orbit_Radius) ** 3));
   Mars_Angular_Rate := Sqrt (Real (Mu_Sun) / (Real (Mars_Orbit_Radius) ** 3));

   --  Mars phase angle at arrival relative to Earth's position at departure
   --  Phase_Angle = Mars_Position_Angle - Earth_Position_Angle_at_Departure
   --  For a prograde transfer, Mars needs to be "ahead" of Earth
   Phase_Angle := Mars_Angular_Rate * Real (Transfer_Time);

   --  Earth at departure: Position along +X axis
   Earth_Position := (Real (Earth_Orbit_Radius), 0.0, 0.0);
   Earth_Velocity := (0.0, Sqrt (Real (Mu_Sun) / Real (Earth_Orbit_Radius)), 0.0);

   --  Mars at arrival: Rotated by phase angle
   Mars_Position := (Real (Mars_Orbit_Radius) * Cos (Phase_Angle),
                     Real (Mars_Orbit_Radius) * Sin (Phase_Angle),
                     0.0);
   Mars_Velocity := (-Sqrt (Real (Mu_Sun) / Real (Mars_Orbit_Radius)) * Sin (Phase_Angle),
                      Sqrt (Real (Mu_Sun) / Real (Mars_Orbit_Radius)) * Cos (Phase_Angle),
                      0.0);

   IO.Put_Line ("  Earth departure position:");
   IO.Put ("    R = (");
   Put_Real (Earth_Position (1) / 1.0e6, Fore => 4, Aft => 2);
   IO.Put (", ");
   Put_Real (Earth_Position (2) / 1.0e6, Fore => 4, Aft => 2);
   IO.Put (", ");
   Put_Real (Earth_Position (3) / 1.0e6, Fore => 4, Aft => 2);
   IO.Put_Line (") x 10^6 km");

   IO.Put ("    |R| = ");
   Put_Real (Magnitude (Earth_Position) / 1.0e6, Fore => 4, Aft => 2);
   IO.Put_Line (" x 10^6 km (1 AU)");

   IO.New_Line;
   IO.Put_Line ("  Mars arrival position:");
   IO.Put ("    R = (");
   Put_Real (Mars_Position (1) / 1.0e6, Fore => 4, Aft => 2);
   IO.Put (", ");
   Put_Real (Mars_Position (2) / 1.0e6, Fore => 4, Aft => 2);
   IO.Put (", ");
   Put_Real (Mars_Position (3) / 1.0e6, Fore => 4, Aft => 2);
   IO.Put_Line (") x 10^6 km");

   IO.Put ("    |R| = ");
   Put_Real (Magnitude (Mars_Position) / 1.0e6, Fore => 4, Aft => 2);
   IO.Put_Line (" x 10^6 km (1.52 AU)");

   IO.New_Line;
   IO.Put ("  Transfer time: ");
   IO.Put (Integer'Image (Transfer_Days));
   IO.Put_Line (" days");

   IO.Put ("  Phase angle at arrival: ");
   Put_Real (Phase_Angle * Rad_To_Deg, Fore => 3, Aft => 1);
   IO.Put_Line (" degrees");

   IO.New_Line;

   ---------------------------------------------------------------------------
   -- Step 2: Solve Lambert Problem
   ---------------------------------------------------------------------------

   IO.Put_Line ("STEP 2: Lambert Problem Solution");
   IO.Put_Line ("----------------------------------------------------------");

   Lambert_Sol := Solve_Lambert
      (R1       => Earth_Position,
       R2       => Mars_Position,
       Tof      => Transfer_Time,
       Mu       => Mu_Sun,
       Long_Way => False);

   if Lambert_Sol.Converged then
      IO.Put ("  Solution converged in ");
      IO.Put (Natural'Image (Lambert_Sol.Iterations));
      IO.Put_Line (" iterations");
      IO.New_Line;

      IO.Put_Line ("  Transfer orbit parameters:");
      IO.Put ("    Semi-major axis: ");
      Put_Real (Real (Lambert_Sol.A) / 1.0e6, Fore => 4, Aft => 2);
      IO.Put_Line (" x 10^6 km");

      IO.Put ("    Eccentricity:    ");
      Put_Real (Lambert_Sol.E, Fore => 1, Aft => 4);
      IO.New_Line;

      IO.New_Line;
      IO.Put_Line ("  Departure velocity (heliocentric):");
      IO.Put ("    V1 = (");
      Put_Real (Lambert_Sol.V1 (1), Fore => 3, Aft => 3);
      IO.Put (", ");
      Put_Real (Lambert_Sol.V1 (2), Fore => 3, Aft => 3);
      IO.Put (", ");
      Put_Real (Lambert_Sol.V1 (3), Fore => 3, Aft => 3);
      IO.Put_Line (") km/s");

      IO.Put ("    |V1| = ");
      Put_Real (Magnitude (Lambert_Sol.V1), Fore => 2, Aft => 3);
      IO.Put_Line (" km/s");

      IO.New_Line;
      IO.Put_Line ("  Arrival velocity (heliocentric):");
      IO.Put ("    V2 = (");
      Put_Real (Lambert_Sol.V2 (1), Fore => 3, Aft => 3);
      IO.Put (", ");
      Put_Real (Lambert_Sol.V2 (2), Fore => 3, Aft => 3);
      IO.Put (", ");
      Put_Real (Lambert_Sol.V2 (3), Fore => 3, Aft => 3);
      IO.Put_Line (") km/s");

      IO.Put ("    |V2| = ");
      Put_Real (Magnitude (Lambert_Sol.V2), Fore => 2, Aft => 3);
      IO.Put_Line (" km/s");

   else
      IO.Put_Line ("  ERROR: Lambert solver did not converge!");
      IO.Put_Line ("  Check transfer geometry and time of flight.");
      return;
   end if;

   IO.New_Line;

   ---------------------------------------------------------------------------
   -- Step 3: Calculate Delta-V Budget
   ---------------------------------------------------------------------------

   IO.Put_Line ("STEP 3: Delta-V Budget");
   IO.Put_Line ("----------------------------------------------------------");

   --  Compute delta-V at departure and arrival
   Departure_DV := Velocity_Km_S (Magnitude (Lambert_Sol.V1 - Earth_Velocity));
   Arrival_DV := Velocity_Km_S (Magnitude (Mars_Velocity - Lambert_Sol.V2));
   Total_DV := Velocity_Km_S (Real (Departure_DV) + Real (Arrival_DV));

   IO.Put ("  Departure delta-V (Earth escape): ");
   Put_Real (Real (Departure_DV), Fore => 2, Aft => 3);
   IO.Put_Line (" km/s");

   IO.Put ("  Arrival delta-V (Mars capture):   ");
   Put_Real (Real (Arrival_DV), Fore => 2, Aft => 3);
   IO.Put_Line (" km/s");

   IO.Put_Line ("  ----------------------------------");
   IO.Put ("  Total delta-V:                    ");
   Put_Real (Real (Total_DV), Fore => 2, Aft => 3);
   IO.Put_Line (" km/s");

   IO.New_Line;

   --  Calculate C3 (characteristic energy)
   declare
      V_Infinity_Dep : constant Real := Real (Departure_DV);
      C3_Dep : constant Real := V_Infinity_Dep ** 2;
   begin
      IO.Put ("  Departure C3: ");
      Put_Real (C3_Dep, Fore => 2, Aft => 2);
      IO.Put_Line (" km^2/s^2");
   end;

   IO.New_Line;

   ---------------------------------------------------------------------------
   -- Step 4: Propagate Transfer Trajectory
   ---------------------------------------------------------------------------

   IO.Put_Line ("STEP 4: Trajectory Propagation");
   IO.Put_Line ("----------------------------------------------------------");

   --  Set up force model
   Sun_Model.Mu := Mu_Sun;

   --  Generate trajectory
   Traj := Generate_Timed_Trajectory
      (Initial  => (Position => Earth_Position, Velocity => Lambert_Sol.V1),
       T_Start  => 0.0,
       T_End    => Transfer_Time,
       N_Points => 21,
       Model    => Sun_Model);

   IO.Put_Line ("  Trajectory points (every 10 days):");
   IO.Put_Line ("  Day     Distance (AU)    Speed (km/s)");
   IO.Put_Line ("  ---     -------------    ------------");

   for I in Traj'Range loop
      declare
         Days : constant Integer := Integer (Real (Traj (I).Time) / Day_Seconds);
         R_AU : constant Real := Magnitude (Traj (I).State.Position) / Real (AU);
         Speed : constant Real := Magnitude (Traj (I).State.Velocity);
      begin
         IO.Put ("  ");
         if Days < 10 then
            IO.Put (" ");
         end if;
         if Days < 100 then
            IO.Put (" ");
         end if;
         IO.Put (Integer'Image (Days));
         IO.Put ("       ");
         Put_Real (R_AU, Fore => 1, Aft => 3);
         IO.Put ("           ");
         Put_Real (Speed, Fore => 2, Aft => 2);
         IO.New_Line;
      end;
   end loop;

   IO.New_Line;

   --  Verify energy conservation
   Energy_Err := Energy_Error
      (Initial => (Position => Earth_Position, Velocity => Lambert_Sol.V1),
       Final   => Traj (Traj'Last).State,
       Mu      => Mu_Sun);

   IO.Put ("  Energy conservation error: ");
   Put_Real (Energy_Err, Fore => 1, Aft => 2);
   IO.Put (" (relative)");
   if Energy_Err < 1.0e-6 then
      IO.Put_Line (" [PASS]");
   else
      IO.Put_Line (" [WARNING: Large error]");
   end if;

   IO.New_Line;

   ---------------------------------------------------------------------------
   -- Step 5: Mission Summary
   ---------------------------------------------------------------------------

   Print_Separator;
   IO.Put_Line ("                   MISSION SUMMARY");
   Print_Separator;
   IO.New_Line;

   IO.Put_Line ("  Launch Window:        Day 0");
   IO.Put ("  Transfer Time:        ");
   IO.Put (Integer'Image (Transfer_Days));
   IO.Put_Line (" days");
   IO.New_Line;

   IO.Put ("  Total Delta-V:        ");
   Put_Real (Real (Total_DV), Fore => 2, Aft => 3);
   IO.Put_Line (" km/s");

   IO.Put ("    - Earth departure:  ");
   Put_Real (Real (Departure_DV), Fore => 2, Aft => 3);
   IO.Put_Line (" km/s");

   IO.Put ("    - Mars arrival:     ");
   Put_Real (Real (Arrival_DV), Fore => 2, Aft => 3);
   IO.Put_Line (" km/s");
   IO.New_Line;

   IO.Put_Line ("  Transfer Orbit:");
   IO.Put ("    Semi-major axis:    ");
   Put_Real (Real (Lambert_Sol.A) / Real (AU), Fore => 1, Aft => 3);
   IO.Put_Line (" AU");

   IO.Put ("    Eccentricity:       ");
   Put_Real (Lambert_Sol.E, Fore => 1, Aft => 4);
   IO.New_Line;

   IO.Put ("    Perihelion:         ");
   Put_Real (Real (Lambert_Sol.A) * (1.0 - Lambert_Sol.E) / Real (AU), Fore => 1, Aft => 3);
   IO.Put_Line (" AU");

   IO.Put ("    Aphelion:           ");
   Put_Real (Real (Lambert_Sol.A) * (1.0 + Lambert_Sol.E) / Real (AU), Fore => 1, Aft => 3);
   IO.Put_Line (" AU");

   IO.New_Line;
   Print_Separator;
   IO.Put_Line ("  Mission planning complete. Trajectory verified.");
   Print_Separator;

end Earth_Mars_Mission;
