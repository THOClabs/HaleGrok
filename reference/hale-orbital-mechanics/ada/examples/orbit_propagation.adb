-------------------------------------------------------------------------------
-- Example: Orbit Propagation
-------------------------------------------------------------------------------
-- This example demonstrates propagating an orbit through time using
-- Kepler's equation and the universal variable formulation.
--
-- Shows the progression of an elliptical orbit through one complete period.
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;
with Hale_Orbital.Elements;  use Hale_Orbital.Elements;
with Hale_Orbital.Kepler;    use Hale_Orbital.Kepler;
with Hale_Orbital.Vectors;   use Hale_Orbital.Vectors;

procedure Orbit_Propagation is

   package IO renames Ada.Text_IO;
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   --  Define an elliptical orbit (Molniya-like)
   --  High eccentricity for interesting motion
   Initial_Elements : Orbital_Elements;
   Period : Time_Seconds;
   State : State_Vector;
   Elements_Propagated : Orbital_Elements;

   --  Time steps
   Num_Steps : constant := 12;
   Dt : Time_Seconds;

begin
   IO.Put_Line ("=========================================================");
   IO.Put_Line ("  Orbit Propagation Demo");
   IO.Put_Line ("  HALE Orbital Mechanics Library - Ada 2012");
   IO.Put_Line ("=========================================================");
   IO.New_Line;

   --  Initialize orbit (Molniya-type: 500 km perigee, 40000 km apogee)
   Initial_Elements.Semi_Major_Axis := 20250.0;  -- km
   Initial_Elements.Eccentricity := 0.74;
   Initial_Elements.Inclination := Angle_Radians (63.4 * Deg_To_Rad);
   Initial_Elements.RAAN := Angle_Radians (0.0);
   Initial_Elements.Argument_Of_Periapsis := Angle_Radians (270.0 * Deg_To_Rad);
   Initial_Elements.True_Anomaly := Angle_Radians (0.0);  -- Start at periapsis

   --  Calculate orbital period
   Period := Orbital_Period (Initial_Elements.Semi_Major_Axis, Mu_Earth);
   Dt := Time_Seconds (Real (Period) / Real (Num_Steps));

   IO.Put_Line ("Initial Orbital Elements:");
   IO.Put_Line ("  Semi-major axis:    " &
                Distance_Km'Image (Initial_Elements.Semi_Major_Axis) & " km");
   IO.Put_Line ("  Eccentricity:       " &
                Real'Image (Initial_Elements.Eccentricity));
   IO.Put_Line ("  Inclination:        " &
                Real'Image (Real (Initial_Elements.Inclination) * Rad_To_Deg) & " deg");
   IO.Put_Line ("  RAAN:               " &
                Real'Image (Real (Initial_Elements.RAAN) * Rad_To_Deg) & " deg");
   IO.Put_Line ("  Arg of Periapsis:   " &
                Real'Image (Real (Initial_Elements.Argument_Of_Periapsis) * Rad_To_Deg) & " deg");
   IO.New_Line;

   IO.Put_Line ("Derived Parameters:");
   IO.Put_Line ("  Orbital period:     " & Time_Seconds'Image (Period) & " s");
   IO.Put_Line ("                      " & Real'Image (Real (Period) / 3600.0) & " hours");
   IO.Put_Line ("  Periapsis radius:   " &
                Distance_Km'Image (Periapsis_Distance (Initial_Elements.Semi_Major_Axis,
                                                       Initial_Elements.Eccentricity)) & " km");
   IO.Put_Line ("  Apoapsis radius:    " &
                Distance_Km'Image (Apoapsis_Distance (Initial_Elements.Semi_Major_Axis,
                                                      Initial_Elements.Eccentricity)) & " km");
   IO.New_Line;

   --  Convert to state vector
   State := Elements_To_State (Initial_Elements, Mu_Earth);

   IO.Put_Line ("Initial State Vector:");
   IO.Put_Line ("  Position: (" &
                Real'Image (State.Position (1)) & ", " &
                Real'Image (State.Position (2)) & ", " &
                Real'Image (State.Position (3)) & ") km");
   IO.Put_Line ("  Velocity: (" &
                Real'Image (State.Velocity (1)) & ", " &
                Real'Image (State.Velocity (2)) & ", " &
                Real'Image (State.Velocity (3)) & ") km/s");
   IO.New_Line;

   --  Propagate through one orbit
   IO.Put_Line ("Propagation through one orbital period:");
   IO.Put_Line ("  Step   Time (hr)    Radius (km)    True Anomaly (deg)    Speed (km/s)");
   IO.Put_Line ("  ----   ---------    -----------    ------------------    ------------");

   for Step in 0 .. Num_Steps loop
      declare
         T : constant Time_Seconds := Time_Seconds (Real (Step) * Real (Dt));
         Propagated_State : State_Vector := State;
         R_Mag : Real;
         V_Mag : Real;
         Nu : Angle_Radians;
      begin
         if Step > 0 then
            Propagate (Propagated_State, Time_Seconds (Real (Step) * Real (Dt)), Mu_Earth);
         end if;

         R_Mag := Magnitude (Propagated_State.Position);
         V_Mag := Magnitude (Propagated_State.Velocity);

         --  Convert back to elements to get true anomaly
         Elements_Propagated := State_To_Elements (Propagated_State.Position,
                                                   Propagated_State.Velocity,
                                                   Mu_Earth);
         Nu := Elements_Propagated.True_Anomaly;

         IO.Put ("  ");
         IO.Put (Natural'Image (Step));
         IO.Put ("      ");
         IO.Put (Real'Image (Real (T) / 3600.0));
         IO.Put ("      ");
         IO.Put (Real'Image (R_Mag));
         IO.Put ("      ");
         IO.Put (Real'Image (Real (Nu) * Rad_To_Deg));
         IO.Put ("          ");
         IO.Put_Line (Real'Image (V_Mag));
      end;
   end loop;

   IO.New_Line;
   IO.Put_Line ("Note: Radius minimum at periapsis (nu=0), maximum at apoapsis (nu=180)");
   IO.Put_Line ("      Velocity maximum at periapsis, minimum at apoapsis (Kepler's 2nd law)");
   IO.New_Line;

   IO.Put_Line ("=========================================================");

end Orbit_Propagation;
