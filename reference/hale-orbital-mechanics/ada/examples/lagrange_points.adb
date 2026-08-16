-------------------------------------------------------------------------------
-- Example: Lagrange Point Computation
-------------------------------------------------------------------------------
-- This example demonstrates calculating the five Lagrange points
-- for the Earth-Moon and Sun-Earth systems.
--
-- Lagrange points are equilibrium positions in the CR3BP where
-- a small mass can remain stationary relative to the two primaries.
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Types;      use Hale_Orbital.Types;
with Hale_Orbital.Threebody;  use Hale_Orbital.Threebody;

procedure Lagrange_Points is

   package IO renames Ada.Text_IO;
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   procedure Print_System_Lagrange_Points (System : Threebody_System) is
      Points : Lagrange_Array;
      Stability : Stability_Result;
   begin
      IO.Put_Line ("System: " & System.Name);
      IO.Put_Line ("  Mass ratio (mu): " & Real'Image (System.Mass_Ratio));
      IO.Put_Line ("  Separation:      " & Distance_Km'Image (System.Distance) & " km");
      IO.New_Line;

      Points := Compute_All_Lagrange_Points (System);

      IO.Put_Line ("  Point    X (norm)      Y (norm)      Distance (km)    Stable?");
      IO.Put_Line ("  -----    --------      --------      -------------    -------");

      for P in Lagrange_Point loop
         Stability := Analyze_Stability (System, P);

         IO.Put ("  " & Lagrange_Point'Image (P));
         IO.Put ("      ");
         IO.Put (Real'Image (Points (P).X));
         IO.Put ("   ");
         IO.Put (Real'Image (Points (P).Y));
         IO.Put ("   ");
         IO.Put (Distance_Km'Image (Points (P).Distance));
         IO.Put ("   ");
         if Stability.Is_Stable then
            IO.Put_Line ("Yes");
         else
            IO.Put_Line ("No");
         end if;
      end loop;

      IO.New_Line;
   end Print_System_Lagrange_Points;

begin
   IO.Put_Line ("=========================================================");
   IO.Put_Line ("  Lagrange Point Calculator");
   IO.Put_Line ("  HALE Orbital Mechanics Library - Ada 2012");
   IO.Put_Line ("=========================================================");
   IO.New_Line;

   --  Earth-Moon System
   Print_System_Lagrange_Points (Earth_Moon_System);

   --  Sun-Earth System
   Print_System_Lagrange_Points (Sun_Earth_System);

   --  Sun-Jupiter System
   Print_System_Lagrange_Points (Sun_Jupiter_System);

   IO.Put_Line ("Notes:");
   IO.Put_Line ("  - L1, L2, L3 are collinear points (always unstable)");
   IO.Put_Line ("  - L4, L5 are triangular points (stable if mu < 0.0385)");
   IO.Put_Line ("  - X coordinate is along the line connecting the primaries");
   IO.Put_Line ("  - Y coordinate is perpendicular in the orbital plane");
   IO.New_Line;

   IO.Put_Line ("Applications:");
   IO.Put_Line ("  - Earth-Moon L1: Lunar Gateway station");
   IO.Put_Line ("  - Earth-Moon L2: Far-side lunar communications relay");
   IO.Put_Line ("  - Sun-Earth L1: Solar observatories (SOHO, DSCOVR)");
   IO.Put_Line ("  - Sun-Earth L2: Space telescopes (JWST, Gaia)");
   IO.Put_Line ("  - Sun-Jupiter L4/L5: Trojan asteroids");
   IO.New_Line;

   IO.Put_Line ("=========================================================");

end Lagrange_Points;
