-------------------------------------------------------------------------------
-- Example: Hohmann Transfer from LEO to GEO
-------------------------------------------------------------------------------
-- This example demonstrates calculating a Hohmann transfer orbit
-- from Low Earth Orbit (LEO) to Geostationary Earth Orbit (GEO).
--
-- Based on: Hale, F.J. (1994). Introduction to Space Flight. Chapter 5.
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;
with Hale_Orbital.Maneuvers; use Hale_Orbital.Maneuvers;

procedure Hohmann_Transfer is

   package IO renames Ada.Text_IO;
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   --  Mission parameters
   LEO_Altitude : constant Distance_Km := 300.0;   -- 300 km parking orbit
   R_LEO : constant Distance_Km := Distance_Km (Real (R_Earth) + Real (LEO_Altitude));

   --  Calculate the transfer
   Result : Hohmann_Result;
   V_LEO, V_GEO : Velocity_Km_S;

begin
   IO.Put_Line ("=========================================================");
   IO.Put_Line ("  Hohmann Transfer: LEO to GEO");
   IO.Put_Line ("  HALE Orbital Mechanics Library - Ada 2012");
   IO.Put_Line ("=========================================================");
   IO.New_Line;

   --  Display initial conditions
   IO.Put_Line ("Initial Conditions:");
   IO.Put_Line ("  LEO altitude:  " & Distance_Km'Image (LEO_Altitude) & " km");
   IO.Put_Line ("  LEO radius:    " & Distance_Km'Image (R_LEO) & " km");
   IO.Put_Line ("  GEO radius:    " & Distance_Km'Image (R_GEO) & " km");
   IO.Put_Line ("  Earth GM:      " & Gravitational_Parameter'Image (Mu_Earth) & " km^3/s^2");
   IO.New_Line;

   --  Calculate circular velocities
   V_LEO := Circular_Velocity (R_LEO, Mu_Earth);
   V_GEO := Circular_Velocity (R_GEO, Mu_Earth);

   IO.Put_Line ("Circular Orbit Velocities:");
   IO.Put_Line ("  V_LEO:         " & Velocity_Km_S'Image (V_LEO) & " km/s");
   IO.Put_Line ("  V_GEO:         " & Velocity_Km_S'Image (V_GEO) & " km/s");
   IO.New_Line;

   --  Calculate Hohmann transfer
   Result := Hohmann_Transfer (R_LEO, R_GEO, Mu_Earth);

   IO.Put_Line ("Hohmann Transfer Results:");
   IO.Put_Line ("  Delta-V1 (departure burn): " & Velocity_Km_S'Image (Result.Delta_V1) & " km/s");
   IO.Put_Line ("  Delta-V2 (arrival burn):   " & Velocity_Km_S'Image (Result.Delta_V2) & " km/s");
   IO.Put_Line ("  Total Delta-V:             " & Velocity_Km_S'Image (Result.Total_Delta_V) & " km/s");
   IO.New_Line;

   IO.Put_Line ("Transfer Orbit:");
   IO.Put_Line ("  Semi-major axis:           " &
                Distance_Km'Image (Result.A_Transfer) & " km");
   IO.Put_Line ("  Eccentricity:              " &
                Real'Image (Result.E_Transfer));
   IO.Put_Line ("  Transfer time:             " &
                Time_Seconds'Image (Result.Transfer_Time) & " s");
   IO.Put_Line ("  Transfer time:             " &
                Real'Image (Real (Result.Transfer_Time) / 3600.0) & " hours");
   IO.New_Line;

   --  Compare with escape velocity
   IO.Put_Line ("For Reference:");
   IO.Put_Line ("  Escape velocity from LEO:  " &
                Velocity_Km_S'Image (Escape_Velocity (R_LEO, Mu_Earth)) & " km/s");
   IO.Put_Line ("  GEO orbital period:        " &
                Real'Image (Real (Orbital_Period (R_GEO, Mu_Earth)) / 3600.0) & " hours");
   IO.New_Line;

   IO.Put_Line ("=========================================================");
   IO.Put_Line ("  Calculation complete.");
   IO.Put_Line ("=========================================================");

end Hohmann_Transfer;
