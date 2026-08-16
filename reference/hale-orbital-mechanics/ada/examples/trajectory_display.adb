-------------------------------------------------------------------------------
-- Example: Trajectory Visualization / CSV Export
-------------------------------------------------------------------------------
-- Generates trajectory data in CSV format for visualization with external
-- tools like gnuplot, matplotlib, or any spreadsheet application.
--
-- This example shows:
--   1. Propagating an orbit and recording trajectory points
--   2. Outputting data in CSV format
--   3. Multiple output formats (Cartesian, orbital elements, etc.)
--
-- Output can be used with:
--   gnuplot: plot "trajectory.csv" using 2:3 with lines
--   Python:  pd.read_csv("trajectory.csv")
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Types;       use Hale_Orbital.Types;
with Hale_Orbital.Constants;   use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;     use Hale_Orbital.Vectors;
with Hale_Orbital.Twobody;     use Hale_Orbital.Twobody;
with Hale_Orbital.Elements;    use Hale_Orbital.Elements;
with Hale_Orbital.Propagation; use Hale_Orbital.Propagation;

procedure Trajectory_Display is

   package IO renames Ada.Text_IO;
   package CLI renames Ada.Command_Line;
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   ---------------------------------------------------------------------------
   -- Output file handling
   ---------------------------------------------------------------------------

   Output_File : IO.File_Type;
   Output_Filename : constant String := "trajectory.csv";

   ---------------------------------------------------------------------------
   -- Orbit Configuration
   ---------------------------------------------------------------------------

   --  Default: Molniya-type orbit (highly elliptical)
   --  Can be modified via command line arguments

   Initial_Elements : Orbital_Elements;
   Num_Orbits : constant := 2;
   Points_Per_Orbit : constant := 100;
   Total_Points : constant := Num_Orbits * Points_Per_Orbit;

   --  Force model
   Sun_Model : Two_Body_Model;

   ---------------------------------------------------------------------------
   -- Helper Procedures
   ---------------------------------------------------------------------------

   procedure Put_Real_CSV (F : IO.File_Type; Value : Real) is
      S : String (1 .. 25);
      package Real_IO is new Ada.Text_IO.Float_IO (Real);
   begin
      Real_IO.Put (S, Value, Aft => 9, Exp => 0);
      --  Trim leading spaces
      for I in S'Range loop
         if S (I) /= ' ' then
            IO.Put (F, S (I .. S'Last));
            return;
         end if;
      end loop;
   end Put_Real_CSV;

   procedure Print_Usage is
   begin
      IO.Put_Line ("Usage: trajectory_display [orbit_type]");
      IO.Put_Line ("");
      IO.Put_Line ("  orbit_type:");
      IO.Put_Line ("    leo       - Low Earth Orbit (circular, 400 km)");
      IO.Put_Line ("    molniya   - Molniya orbit (highly elliptical)");
      IO.Put_Line ("    geo       - Geostationary orbit");
      IO.Put_Line ("    transfer  - Hohmann transfer LEO to GEO");
      IO.Put_Line ("    mars      - Earth-Mars heliocentric transfer");
      IO.Put_Line ("");
      IO.Put_Line ("Output: trajectory.csv");
   end Print_Usage;

begin
   IO.Put_Line ("==========================================================");
   IO.Put_Line ("     TRAJECTORY VISUALIZATION / CSV EXPORT");
   IO.Put_Line ("     HALE Orbital Mechanics Library - Ada 2012");
   IO.Put_Line ("==========================================================");
   IO.New_Line;

   ---------------------------------------------------------------------------
   -- Parse command line arguments
   ---------------------------------------------------------------------------

   declare
      Orbit_Type : String (1 .. 10) := "molniya   ";
   begin
      if CLI.Argument_Count >= 1 then
         declare
            Arg : constant String := CLI.Argument (1);
         begin
            if Arg = "--help" or Arg = "-h" then
               Print_Usage;
               return;
            end if;
            Orbit_Type := (others => ' ');
            Orbit_Type (1 .. Arg'Length) := Arg;
         end;
      end if;

      --  Configure orbit based on type
      if Orbit_Type (1 .. 3) = "leo" then
         IO.Put_Line ("Orbit: Low Earth Orbit (400 km circular)");
         Initial_Elements.Semi_Major_Axis := R_Earth + 400.0;
         Initial_Elements.Eccentricity := 0.001;
         Initial_Elements.Inclination := Angle_Radians (51.6 * Deg_To_Rad);
         Initial_Elements.RAAN := 0.0;
         Initial_Elements.Argument_Of_Periapsis := 0.0;
         Initial_Elements.True_Anomaly := 0.0;
         Sun_Model.Mu := Mu_Earth;

      elsif Orbit_Type (1 .. 7) = "molniya" then
         IO.Put_Line ("Orbit: Molniya (highly elliptical)");
         Initial_Elements.Semi_Major_Axis := 26600.0;
         Initial_Elements.Eccentricity := 0.74;
         Initial_Elements.Inclination := Angle_Radians (63.4 * Deg_To_Rad);
         Initial_Elements.RAAN := 0.0;
         Initial_Elements.Argument_Of_Periapsis := Angle_Radians (270.0 * Deg_To_Rad);
         Initial_Elements.True_Anomaly := 0.0;
         Sun_Model.Mu := Mu_Earth;

      elsif Orbit_Type (1 .. 3) = "geo" then
         IO.Put_Line ("Orbit: Geostationary");
         Initial_Elements.Semi_Major_Axis := R_GEO;
         Initial_Elements.Eccentricity := 0.0001;
         Initial_Elements.Inclination := 0.0;
         Initial_Elements.RAAN := 0.0;
         Initial_Elements.Argument_Of_Periapsis := 0.0;
         Initial_Elements.True_Anomaly := 0.0;
         Sun_Model.Mu := Mu_Earth;

      elsif Orbit_Type (1 .. 8) = "transfer" then
         IO.Put_Line ("Orbit: Hohmann Transfer (LEO to GEO)");
         Initial_Elements.Semi_Major_Axis := (R_Earth + 400.0 + R_GEO) / 2.0;
         Initial_Elements.Eccentricity :=
            Real (abs (R_GEO - (R_Earth + 400.0))) / Real (R_GEO + R_Earth + 400.0);
         Initial_Elements.Inclination := 0.0;
         Initial_Elements.RAAN := 0.0;
         Initial_Elements.Argument_Of_Periapsis := 0.0;
         Initial_Elements.True_Anomaly := 0.0;
         Sun_Model.Mu := Mu_Earth;

      elsif Orbit_Type (1 .. 4) = "mars" then
         IO.Put_Line ("Orbit: Earth-Mars Heliocentric Transfer");
         Initial_Elements.Semi_Major_Axis := (AU + A_Mars) / 2.0;
         Initial_Elements.Eccentricity :=
            abs (Real (A_Mars) - Real (AU)) / (Real (A_Mars) + Real (AU));
         Initial_Elements.Inclination := 0.0;
         Initial_Elements.RAAN := 0.0;
         Initial_Elements.Argument_Of_Periapsis := 0.0;
         Initial_Elements.True_Anomaly := 0.0;
         Sun_Model.Mu := Mu_Sun;

      else
         IO.Put_Line ("Unknown orbit type. Using Molniya.");
         Initial_Elements.Semi_Major_Axis := 26600.0;
         Initial_Elements.Eccentricity := 0.74;
         Initial_Elements.Inclination := Angle_Radians (63.4 * Deg_To_Rad);
         Initial_Elements.RAAN := 0.0;
         Initial_Elements.Argument_Of_Periapsis := Angle_Radians (270.0 * Deg_To_Rad);
         Initial_Elements.True_Anomaly := 0.0;
         Sun_Model.Mu := Mu_Earth;
      end if;
   end;

   IO.New_Line;

   ---------------------------------------------------------------------------
   -- Display orbit parameters
   ---------------------------------------------------------------------------

   IO.Put_Line ("Orbit Parameters:");
   IO.Put_Line ("  Semi-major axis: " & Distance_Km'Image (Initial_Elements.Semi_Major_Axis) & " km");
   IO.Put_Line ("  Eccentricity:    " & Real'Image (Initial_Elements.Eccentricity));
   IO.Put_Line ("  Inclination:     " & Real'Image (Real (Initial_Elements.Inclination) * Rad_To_Deg) & " deg");
   IO.Put_Line ("  RAAN:            " & Real'Image (Real (Initial_Elements.RAAN) * Rad_To_Deg) & " deg");
   IO.Put_Line ("  Arg Periapsis:   " & Real'Image (Real (Initial_Elements.Argument_Of_Periapsis) * Rad_To_Deg) & " deg");
   IO.New_Line;

   declare
      Period : constant Time_Seconds := Orbital_Period (Initial_Elements.Semi_Major_Axis, Sun_Model.Mu);
   begin
      IO.Put_Line ("  Orbital period:  " & Real'Image (Real (Period) / 3600.0) & " hours");
   end;

   IO.New_Line;
   IO.Put_Line ("Generating trajectory (" & Integer'Image (Total_Points) & " points)...");

   ---------------------------------------------------------------------------
   -- Generate and output trajectory
   ---------------------------------------------------------------------------

   IO.Create (Output_File, IO.Out_File, Output_Filename);

   --  Write CSV header
   IO.Put_Line (Output_File, "time_s,time_hr,x_km,y_km,z_km,vx_km_s,vy_km_s,vz_km_s,r_km,v_km_s,a_km,e,nu_deg");

   --  Convert to state vector
   declare
      Initial_State : constant State_Vector := Elements_To_State (Initial_Elements, Sun_Model.Mu);
      Period : constant Time_Seconds := Orbital_Period (Initial_Elements.Semi_Major_Axis, Sun_Model.Mu);
      Total_Time : constant Time_Seconds := Time_Seconds (Real (Num_Orbits) * Real (Period));
      Dt : constant Time_Seconds := Time_Seconds (Real (Total_Time) / Real (Total_Points - 1));

      Current_State : State_Vector := Initial_State;
      T : Time_Seconds := 0.0;
      Step : constant Time_Seconds := Time_Seconds (Real (Dt) / 10.0);  -- Integration substep

   begin
      for I in 1 .. Total_Points loop
         --  Compute derived quantities
         declare
            R_Mag : constant Real := Magnitude (Current_State.Position);
            V_Mag : constant Real := Magnitude (Current_State.Velocity);
            Elem : Orbital_Elements;
         begin
            --  Get current orbital elements
            Elem := State_To_Elements (Current_State.Position, Current_State.Velocity, Sun_Model.Mu);

            --  Write CSV row
            Put_Real_CSV (Output_File, Real (T));
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, Real (T) / 3600.0);
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, Current_State.Position (1));
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, Current_State.Position (2));
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, Current_State.Position (3));
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, Current_State.Velocity (1));
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, Current_State.Velocity (2));
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, Current_State.Velocity (3));
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, R_Mag);
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, V_Mag);
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, Real (Elem.Semi_Major_Axis));
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, Elem.Eccentricity);
            IO.Put (Output_File, ",");
            Put_Real_CSV (Output_File, Real (Elem.True_Anomaly) * Rad_To_Deg);
            IO.New_Line (Output_File);
         end;

         --  Propagate to next point
         if I < Total_Points then
            Current_State := Propagate_RK4 (Current_State, T, T + Dt, Step, Sun_Model);
            T := T + Dt;
         end if;
      end loop;
   end;

   IO.Close (Output_File);

   IO.Put_Line ("Done!");
   IO.New_Line;
   IO.Put_Line ("Output written to: " & Output_Filename);
   IO.New_Line;

   ---------------------------------------------------------------------------
   -- Usage hints
   ---------------------------------------------------------------------------

   IO.Put_Line ("==========================================================");
   IO.Put_Line ("VISUALIZATION COMMANDS:");
   IO.Put_Line ("==========================================================");
   IO.New_Line;
   IO.Put_Line ("gnuplot:");
   IO.Put_Line ("  set datafile separator ','");
   IO.Put_Line ("  plot 'trajectory.csv' using 3:4 with lines title 'XY Plane'");
   IO.Put_Line ("  splot 'trajectory.csv' using 3:4:5 with lines title '3D'");
   IO.New_Line;
   IO.Put_Line ("Python/matplotlib:");
   IO.Put_Line ("  import pandas as pd");
   IO.Put_Line ("  import matplotlib.pyplot as plt");
   IO.Put_Line ("  df = pd.read_csv('trajectory.csv')");
   IO.Put_Line ("  plt.plot(df['x_km'], df['y_km'])");
   IO.Put_Line ("  plt.axis('equal'); plt.show()");
   IO.New_Line;
   IO.Put_Line ("==========================================================");

end Trajectory_Display;
