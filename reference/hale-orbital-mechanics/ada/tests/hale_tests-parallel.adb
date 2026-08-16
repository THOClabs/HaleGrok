-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Parallel Propagation Test Suite (ISS-031)
-------------------------------------------------------------------------------

with Ada.Text_IO;             use Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;

with Hale_Orbital.Types;       use Hale_Orbital.Types;
with Hale_Orbital.Constants;   use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;     use Hale_Orbital.Vectors;
with Hale_Orbital.Propagation; use Hale_Orbital.Propagation;
with Hale_Tests.Runner;

package body Hale_Tests.Parallel is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   --  Test tolerances
   Position_Tolerance : constant Real := 1.0e-6;   -- 1 mm
   Velocity_Tolerance : constant Real := 1.0e-9;   -- 1 nm/s
   Energy_Tolerance   : constant Real := 1.0e-10;  -- Relative

   --  Test tracking
   Tests_Passed : Natural := 0;
   Tests_Failed : Natural := 0;

   --  Helper: Check if two states are equal within tolerance
   function States_Equal (S1, S2 : State_Vector; Pos_Tol, Vel_Tol : Real) return Boolean is
      Pos_Diff : constant Real := Magnitude (S1.Position - S2.Position);
      Vel_Diff : constant Real := Magnitude (S1.Velocity - S2.Velocity);
   begin
      return Pos_Diff < Pos_Tol and Vel_Diff < Vel_Tol;
   end States_Equal;

   --  Helper: Create LEO state with perturbation
   function Create_LEO_State (Altitude_Km : Real;
                               Perturbation : Vector_3D := Zero_Vector) return State_Vector is
      R : constant Real := Real (R_Earth) + Altitude_Km;
      V : constant Real := Sqrt (Real (Mu_Earth) / R);
   begin
      return (Position => (R, 0.0, 0.0) + Perturbation,
              Velocity => (0.0, V, 0.0));
   end Create_LEO_State;

   ---------------------------------------------------------------------------
   procedure Run_All_Parallel_Tests is
   begin
      Put_Line ("=== Parallel Propagation Tests (ISS-031) ===");

      Tests_Passed := 0;
      Tests_Failed := 0;

      Test_Parallel_Matches_Sequential_RK78;
      Test_Parallel_Matches_Sequential_RK4;
      Test_Parallel_Determinism;
      Test_Monte_Carlo_Ensemble;
      Test_Statistics_Computation;
      Test_Single_Element_Array;
      Test_Large_Ensemble;
      Test_Parallel_Energy_Conservation;
      Test_Mixed_Orbit_Ensemble;
      Test_Zero_Duration_Parallel;

      Put_Line ("--- Parallel Tests Summary ---");
      Put_Line ("Passed:" & Natural'Image (Tests_Passed));
      Put_Line ("Failed:" & Natural'Image (Tests_Failed));
      New_Line;

      --  Fold local tallies into the shared runner so failures reach the
      --  process exit status.
      Hale_Tests.Runner.Record_Results (Tests_Passed, Tests_Failed);
   end Run_All_Parallel_Tests;

   ---------------------------------------------------------------------------
   procedure Test_Parallel_Matches_Sequential_RK78 is
      Model     : constant Two_Body_Model := (Mu => Mu_Earth);
      T_Start   : constant Time_Seconds := 0.0;
      T_End     : constant Time_Seconds := 5400.0;  -- 90 minutes (one orbit)
      Tolerance : constant Real := 1.0e-10;

      --  Create ensemble of 5 LEO orbits at different altitudes
      Samples : State_Array (1 .. 5);
      Parallel_Results : State_Array (1 .. 5);

      All_Match : Boolean := True;
   begin
      --  Initialize samples at different altitudes
      Samples (1) := Create_LEO_State (400.0);
      Samples (2) := Create_LEO_State (450.0);
      Samples (3) := Create_LEO_State (500.0);
      Samples (4) := Create_LEO_State (550.0);
      Samples (5) := Create_LEO_State (600.0);

      --  Propagate in parallel
      Parallel_Results := Propagate_Parallel (Samples, T_Start, T_End, Tolerance, Model);

      --  Compare each result with sequential propagation
      for I in Samples'Range loop
         declare
            Sequential_Result : constant State_Vector :=
               Propagate_RK78 (Samples (I), T_Start, T_End, Tolerance, Model);
         begin
            if not States_Equal (Parallel_Results (I), Sequential_Result,
                                 Position_Tolerance, Velocity_Tolerance) then
               All_Match := False;
               Put_Line ("  MISMATCH at sample" & Integer'Image (I));
            end if;
         end;
      end loop;

      if All_Match then
         Put_Line ("  PASS: Parallel RK78 matches sequential");
         Tests_Passed := Tests_Passed + 1;
      else
         Put_Line ("  FAIL: Parallel RK78 does not match sequential");
         Tests_Failed := Tests_Failed + 1;
      end if;
   end Test_Parallel_Matches_Sequential_RK78;

   ---------------------------------------------------------------------------
   procedure Test_Parallel_Matches_Sequential_RK4 is
      Model   : constant Two_Body_Model := (Mu => Mu_Earth);
      T_Start : constant Time_Seconds := 0.0;
      T_End   : constant Time_Seconds := 5400.0;
      Step    : constant Time_Seconds := 10.0;

      Samples : State_Array (1 .. 5);
      Parallel_Results : State_Array (1 .. 5);

      All_Match : Boolean := True;
   begin
      Samples (1) := Create_LEO_State (400.0);
      Samples (2) := Create_LEO_State (450.0);
      Samples (3) := Create_LEO_State (500.0);
      Samples (4) := Create_LEO_State (550.0);
      Samples (5) := Create_LEO_State (600.0);

      Parallel_Results := Propagate_Parallel_RK4 (Samples, T_Start, T_End, Step, Model);

      for I in Samples'Range loop
         declare
            Sequential_Result : constant State_Vector :=
               Propagate_RK4 (Samples (I), T_Start, T_End, Step, Model);
         begin
            if not States_Equal (Parallel_Results (I), Sequential_Result,
                                 Position_Tolerance, Velocity_Tolerance) then
               All_Match := False;
            end if;
         end;
      end loop;

      if All_Match then
         Put_Line ("  PASS: Parallel RK4 matches sequential");
         Tests_Passed := Tests_Passed + 1;
      else
         Put_Line ("  FAIL: Parallel RK4 does not match sequential");
         Tests_Failed := Tests_Failed + 1;
      end if;
   end Test_Parallel_Matches_Sequential_RK4;

   ---------------------------------------------------------------------------
   procedure Test_Parallel_Determinism is
      Model     : constant Two_Body_Model := (Mu => Mu_Earth);
      T_Start   : constant Time_Seconds := 0.0;
      T_End     : constant Time_Seconds := 5400.0;
      Tolerance : constant Real := 1.0e-10;

      Samples : State_Array (1 .. 10);
      Results_1 : State_Array (1 .. 10);
      Results_2 : State_Array (1 .. 10);
      Results_3 : State_Array (1 .. 10);

      All_Deterministic : Boolean := True;
   begin
      --  Initialize samples
      for I in Samples'Range loop
         Samples (I) := Create_LEO_State (400.0 + Real (I) * 20.0);
      end loop;

      --  Run parallel propagation 3 times
      Results_1 := Propagate_Parallel (Samples, T_Start, T_End, Tolerance, Model);
      Results_2 := Propagate_Parallel (Samples, T_Start, T_End, Tolerance, Model);
      Results_3 := Propagate_Parallel (Samples, T_Start, T_End, Tolerance, Model);

      --  All runs should produce identical results
      for I in Samples'Range loop
         if not States_Equal (Results_1 (I), Results_2 (I), 1.0e-15, 1.0e-18) then
            All_Deterministic := False;
         end if;
         if not States_Equal (Results_2 (I), Results_3 (I), 1.0e-15, 1.0e-18) then
            All_Deterministic := False;
         end if;
      end loop;

      if All_Deterministic then
         Put_Line ("  PASS: Parallel propagation is deterministic");
         Tests_Passed := Tests_Passed + 1;
      else
         Put_Line ("  FAIL: Parallel propagation not deterministic");
         Tests_Failed := Tests_Failed + 1;
      end if;
   end Test_Parallel_Determinism;

   ---------------------------------------------------------------------------
   procedure Test_Monte_Carlo_Ensemble is
      --  Monte Carlo test: Propagate ensemble with initial position uncertainty
      --  Verify final dispersion is reasonable

      Model     : constant Two_Body_Model := (Mu => Mu_Earth);
      T_Start   : constant Time_Seconds := 0.0;
      T_End     : constant Time_Seconds := 5400.0;  -- One orbit
      Tolerance : constant Real := 1.0e-10;

      N_Samples : constant := 20;
      Samples : State_Array (1 .. N_Samples);
      Results : State_Array (1 .. N_Samples);

      --  Initial dispersion: 1 km in position
      Dispersion_Km : constant Real := 1.0;
   begin
      --  Create ensemble with small position perturbations
      for I in Samples'Range loop
         declare
            --  Simple deterministic pseudo-random perturbations
            Angle : constant Real := Real (I) * 2.0 * Pi / Real (N_Samples);
            Perturbation : constant Vector_3D :=
               (Dispersion_Km * Cos (Angle),
                Dispersion_Km * Sin (Angle),
                Dispersion_Km * Cos (Angle) * 0.1);
         begin
            Samples (I) := Create_LEO_State (400.0, Perturbation);
         end;
      end loop;

      --  Propagate ensemble
      Results := Propagate_Parallel (Samples, T_Start, T_End, Tolerance, Model);

      --  Compute statistics
      declare
         Stats : constant Statistics_Record := Compute_Statistics (Results);
         Final_Dispersion : constant Real := Stats.Std_Dev_Position;
      begin
         --  After one orbit, dispersion should grow but not unreasonably
         --  (For circular orbits, dispersion is roughly preserved)
         if Final_Dispersion > 0.0 and Final_Dispersion < 100.0 then
            Put_Line ("  PASS: Monte Carlo ensemble propagated correctly");
            Put_Line ("        Initial dispersion: " & Real'Image (Dispersion_Km) & " km");
            Put_Line ("        Final dispersion:   " & Real'Image (Final_Dispersion) & " km");
            Tests_Passed := Tests_Passed + 1;
         else
            Put_Line ("  FAIL: Monte Carlo dispersion unreasonable");
            Tests_Failed := Tests_Failed + 1;
         end if;
      end;
   end Test_Monte_Carlo_Ensemble;

   ---------------------------------------------------------------------------
   procedure Test_Statistics_Computation is
      --  Test Compute_Statistics with known ensemble

      --  Create simple test ensemble with known statistics
      States : State_Array (1 .. 4);
      Stats : Statistics_Record;

      Mean_Pos_Expected : constant Real := 7000.0;  -- Mean radius
      Tolerance : constant Real := 0.1;
   begin
      --  Create 4 states at cardinal points (same radius)
      States (1) := (Position => (7000.0,    0.0,    0.0),
                     Velocity => (   0.0,  7.5,    0.0));
      States (2) := (Position => (   0.0, 7000.0,    0.0),
                     Velocity => ( -7.5,    0.0,    0.0));
      States (3) := (Position => (-7000.0,   0.0,    0.0),
                     Velocity => (   0.0, -7.5,    0.0));
      States (4) := (Position => (   0.0, -7000.0,   0.0),
                     Velocity => (  7.5,    0.0,    0.0));

      Stats := Compute_Statistics (States);

      --  Mean position should be (0, 0, 0)
      declare
         Mean_Mag : constant Real := Magnitude (Stats.Mean_Position);
      begin
         if Mean_Mag < Tolerance then
            Put_Line ("  PASS: Statistics mean position correct");
            Tests_Passed := Tests_Passed + 1;
         else
            Put_Line ("  FAIL: Statistics mean position incorrect");
            Put_Line ("        Expected: (0, 0, 0), Got magnitude:" & Real'Image (Mean_Mag));
            Tests_Failed := Tests_Failed + 1;
         end if;
      end;

      --  Min and max radius should both be 7000
      if abs (Stats.Min_Radius - 7000.0) < Tolerance and
         abs (Stats.Max_Radius - 7000.0) < Tolerance then
         Put_Line ("  PASS: Statistics radius bounds correct");
         Tests_Passed := Tests_Passed + 1;
      else
         Put_Line ("  FAIL: Statistics radius bounds incorrect");
         Tests_Failed := Tests_Failed + 1;
      end if;
   end Test_Statistics_Computation;

   ---------------------------------------------------------------------------
   procedure Test_Single_Element_Array is
      --  Edge case: Single-element ensemble
      Model   : constant Two_Body_Model := (Mu => Mu_Earth);
      T_Start : constant Time_Seconds := 0.0;
      T_End   : constant Time_Seconds := 3600.0;

      Samples : State_Array (1 .. 1);
      Results : State_Array (1 .. 1);
      Sequential_Result : State_Vector;
   begin
      Samples (1) := Create_LEO_State (400.0);

      Results := Propagate_Parallel (Samples, T_Start, T_End, 1.0e-10, Model);
      Sequential_Result := Propagate_RK78 (Samples (1), T_Start, T_End, 1.0e-10, Model);

      if States_Equal (Results (1), Sequential_Result, Position_Tolerance, Velocity_Tolerance) then
         Put_Line ("  PASS: Single-element parallel propagation correct");
         Tests_Passed := Tests_Passed + 1;
      else
         Put_Line ("  FAIL: Single-element parallel propagation incorrect");
         Tests_Failed := Tests_Failed + 1;
      end if;
   end Test_Single_Element_Array;

   ---------------------------------------------------------------------------
   procedure Test_Large_Ensemble is
      --  Test with large ensemble (100 samples)
      Model   : constant Two_Body_Model := (Mu => Mu_Earth);
      T_Start : constant Time_Seconds := 0.0;
      T_End   : constant Time_Seconds := 3600.0;

      N : constant := 100;
      Samples : State_Array (1 .. N);
      Results : State_Array (1 .. N);

      All_Valid : Boolean := True;
   begin
      --  Initialize 100 samples at varying altitudes
      for I in Samples'Range loop
         Samples (I) := Create_LEO_State (300.0 + Real (I) * 5.0);
      end loop;

      Results := Propagate_Parallel (Samples, T_Start, T_End, 1.0e-10, Model);

      --  Verify all results have reasonable radius (not crashed or escaped)
      for I in Results'Range loop
         declare
            R : constant Real := Magnitude (Results (I).Position);
         begin
            if R < Real (R_Earth) or R > 50000.0 then
               All_Valid := False;
            end if;
         end;
      end loop;

      if All_Valid then
         Put_Line ("  PASS: Large ensemble (100 samples) propagated correctly");
         Tests_Passed := Tests_Passed + 1;
      else
         Put_Line ("  FAIL: Large ensemble has invalid results");
         Tests_Failed := Tests_Failed + 1;
      end if;
   end Test_Large_Ensemble;

   ---------------------------------------------------------------------------
   procedure Test_Parallel_Energy_Conservation is
      --  Verify energy conservation for parallel propagation
      Model     : constant Two_Body_Model := (Mu => Mu_Earth);
      T_Start   : constant Time_Seconds := 0.0;
      T_End     : constant Time_Seconds := 5400.0;
      --  Integrator tolerance 1e-12 gives measured energy drift ~2e-11
      --  (see SDS integrator table), comfortably inside the 1e-10 bar; at
      --  the old 1e-10 integrator tolerance the drift can exceed the bar.
      Tolerance : constant Real := 1.0e-12;

      Samples : State_Array (1 .. 5);
      Results : State_Array (1 .. 5);

      Max_Energy_Error : Real := 0.0;
   begin
      for I in Samples'Range loop
         Samples (I) := Create_LEO_State (400.0 + Real (I) * 50.0);
      end loop;

      Results := Propagate_Parallel (Samples, T_Start, T_End, Tolerance, Model);

      for I in Samples'Range loop
         declare
            Err : constant Real := Energy_Error (Samples (I), Results (I), Mu_Earth);
         begin
            if abs (Err) > Max_Energy_Error then
               Max_Energy_Error := abs (Err);
            end if;
         end;
      end loop;

      if Max_Energy_Error < Energy_Tolerance then
         Put_Line ("  PASS: Parallel energy conservation");
         Put_Line ("        Max relative error:" & Real'Image (Max_Energy_Error));
         Tests_Passed := Tests_Passed + 1;
      else
         Put_Line ("  FAIL: Parallel energy not conserved");
         Put_Line ("        Max relative error:" & Real'Image (Max_Energy_Error));
         Tests_Failed := Tests_Failed + 1;
      end if;
   end Test_Parallel_Energy_Conservation;

   ---------------------------------------------------------------------------
   procedure Test_Mixed_Orbit_Ensemble is
      --  Ensemble with different orbit types (circular, elliptic, inclined)
      Model   : constant Two_Body_Model := (Mu => Mu_Earth);
      T_Start : constant Time_Seconds := 0.0;
      T_End   : constant Time_Seconds := 7200.0;  -- 2 hours

      Samples : State_Array (1 .. 4);
      Results : State_Array (1 .. 4);

      V_Circ : Real;
      All_Valid : Boolean := True;
   begin
      --  Circular LEO
      V_Circ := Sqrt (Real (Mu_Earth) / (Real (R_Earth) + 400.0));
      Samples (1) := (Position => (Real (R_Earth) + 400.0, 0.0, 0.0),
                      Velocity => (0.0, V_Circ, 0.0));

      --  Elliptic (higher velocity for ellipse)
      Samples (2) := (Position => (Real (R_Earth) + 400.0, 0.0, 0.0),
                      Velocity => (0.0, V_Circ * 1.1, 0.0));

      --  Inclined circular
      V_Circ := Sqrt (Real (Mu_Earth) / (Real (R_Earth) + 500.0));
      Samples (3) := (Position => (Real (R_Earth) + 500.0, 0.0, 0.0),
                      Velocity => (0.0, V_Circ * 0.866, V_Circ * 0.5));  -- 30 deg inclination

      --  Polar circular
      V_Circ := Sqrt (Real (Mu_Earth) / (Real (R_Earth) + 600.0));
      Samples (4) := (Position => (Real (R_Earth) + 600.0, 0.0, 0.0),
                      Velocity => (0.0, 0.0, V_Circ));  -- 90 deg inclination

      Results := Propagate_Parallel (Samples, T_Start, T_End, 1.0e-10, Model);

      --  All results should be within reasonable bounds
      for I in Results'Range loop
         declare
            R : constant Real := Magnitude (Results (I).Position);
         begin
            if R < Real (R_Earth) or R > 100000.0 then
               All_Valid := False;
            end if;
         end;
      end loop;

      if All_Valid then
         Put_Line ("  PASS: Mixed orbit ensemble propagated correctly");
         Tests_Passed := Tests_Passed + 1;
      else
         Put_Line ("  FAIL: Mixed orbit ensemble has invalid results");
         Tests_Failed := Tests_Failed + 1;
      end if;
   end Test_Mixed_Orbit_Ensemble;

   ---------------------------------------------------------------------------
   procedure Test_Zero_Duration_Parallel is
      --  Edge case: Zero propagation duration (should return initial states)
      Model : constant Two_Body_Model := (Mu => Mu_Earth);
      T : constant Time_Seconds := 0.0;

      Samples : State_Array (1 .. 3);
      Results : State_Array (1 .. 3);

      All_Match : Boolean := True;
   begin
      for I in Samples'Range loop
         Samples (I) := Create_LEO_State (400.0 + Real (I) * 100.0);
      end loop;

      Results := Propagate_Parallel (Samples, T, T, 1.0e-10, Model);

      for I in Samples'Range loop
         if not States_Equal (Results (I), Samples (I), 1.0e-15, 1.0e-18) then
            All_Match := False;
         end if;
      end loop;

      if All_Match then
         Put_Line ("  PASS: Zero duration returns initial states");
         Tests_Passed := Tests_Passed + 1;
      else
         Put_Line ("  FAIL: Zero duration modified states");
         Tests_Failed := Tests_Failed + 1;
      end if;
   end Test_Zero_Duration_Parallel;

end Hale_Tests.Parallel;
