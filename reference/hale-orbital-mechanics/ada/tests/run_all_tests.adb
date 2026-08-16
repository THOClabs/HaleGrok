-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Comprehensive Test Suite Runner
-------------------------------------------------------------------------------
-- Runs all test suites including:
--   - Core functionality tests (from run_tests.adb)
--   - Edge case tests for numerical robustness
--   - Vallado validation tests for independent verification
--
-- Test count target: 150+ tests for comprehensive coverage (ISS-001)
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Command_Line;
with Hale_Tests.Runner;
with Hale_Tests.Edge_Cases;
with Hale_Tests.Vallado;
with Hale_Tests.Determinism;
with Hale_Tests.Lambert_MultiRev;
with Hale_Tests.Integration;
with Hale_Tests.Parallel;
with Hale_Tests.Periodic_Orbits;
with Hale_Tests.Oracle;

--  Core test procedures from run_tests logic
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Types;      use Hale_Orbital.Types;
with Hale_Orbital.Constants;  use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;    use Hale_Orbital.Vectors;
with Hale_Orbital.Matrices;   use Hale_Orbital.Matrices;
with Hale_Orbital.Twobody;    use Hale_Orbital.Twobody;
with Hale_Orbital.Elements;   use Hale_Orbital.Elements;
with Hale_Orbital.Kepler;     use Hale_Orbital.Kepler;
with Hale_Orbital.Maneuvers;  use Hale_Orbital.Maneuvers;
with Hale_Orbital.Threebody;  use Hale_Orbital.Threebody;
with Hale_Orbital.Propagation; use Hale_Orbital.Propagation;

procedure Run_All_Tests is

   package IO renames Ada.Text_IO;
   package CLI renames Ada.Command_Line;
   package Runner renames Hale_Tests.Runner;

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   function Approx_Equal (A, B : Real; Tolerance : Real := 1.0e-6) return Boolean is
   begin
      return abs (A - B) < Tolerance;
   end Approx_Equal;

   ---------------------------------------------------------------------------
   -- Core Test Suites (from original run_tests.adb)
   ---------------------------------------------------------------------------

   procedure Test_Vectors is
      V1, V2, V3 : Vector_3D;
      Mag : Real;
   begin
      Runner.Start_Suite ("Vector Operations");

      V1 := (1.0, 2.0, 3.0);
      V2 := (4.0, 5.0, 6.0);
      V3 := V1 + V2;
      Runner.Run_Test ("Vector addition",
                       V3 (1) = 5.0 and V3 (2) = 7.0 and V3 (3) = 9.0);

      Runner.Run_Test ("Dot product",
                       Approx_Equal (Dot (V1, V2), 32.0));

      V3 := Cross (V1, V2);
      Runner.Run_Test ("Cross product",
                       Approx_Equal (V3 (1), -3.0) and
                       Approx_Equal (V3 (2), 6.0) and
                       Approx_Equal (V3 (3), -3.0));

      V1 := (3.0, 4.0, 0.0);
      Mag := Magnitude (V1);
      Runner.Run_Test ("Magnitude", Approx_Equal (Mag, 5.0));

      V2 := Normalize (V1);
      Runner.Run_Test ("Normalize",
                       Approx_Equal (V2 (1), 0.6) and Approx_Equal (V2 (2), 0.8));

      Runner.End_Suite;
   end Test_Vectors;

   procedure Test_Matrices is
      M1 : Matrix_3x3;
      V1, V2 : Vector_3D;
      Det : Real;
   begin
      Runner.Start_Suite ("Matrix Operations");

      M1 := Identity_3x3;
      V1 := (1.0, 2.0, 3.0);
      V2 := M1 * V1;
      Runner.Run_Test ("Identity matrix * vector",
                       V2 (1) = V1 (1) and V2 (2) = V1 (2) and V2 (3) = V1 (3));

      M1 := ((1.0, 2.0, 3.0),
             (4.0, 5.0, 6.0),
             (7.0, 8.0, 10.0));
      Det := Determinant (M1);
      Runner.Run_Test ("Determinant", Approx_Equal (Det, -3.0));

      M1 := Rotation_Z (Angle_Radians (Half_Pi));
      V1 := (1.0, 0.0, 0.0);
      V2 := M1 * V1;
      Runner.Run_Test ("Rotation_Z (90 deg)",
                       Approx_Equal (V2 (1), 0.0, 1.0e-10) and
                       Approx_Equal (V2 (2), 1.0, 1.0e-10));

      Runner.End_Suite;
   end Test_Matrices;

   procedure Test_Twobody is
      V_Circ : Velocity_Km_S;
      Period : Time_Seconds;
   begin
      Runner.Start_Suite ("Two-Body Dynamics");

      V_Circ := Circular_Velocity (R_Earth, Mu_Earth);
      Runner.Run_Test ("Circular velocity at Earth surface",
                       Approx_Equal (Real (V_Circ), 7.905, 0.01));

      declare
         V_Esc : constant Velocity_Km_S := Escape_Velocity (R_Earth, Mu_Earth);
      begin
         Runner.Run_Test ("Escape velocity ratio",
                          Approx_Equal (Real (V_Esc) / Real (V_Circ), Sqrt (2.0), 1.0e-6));
      end;

      declare
         R_ISS : constant Distance_Km := Distance_Km (Real (R_Earth) + 420.0);
         T_ISS : constant Time_Seconds := Orbital_Period (R_ISS, Mu_Earth);
      begin
         Runner.Run_Test ("ISS orbital period (~5520 s)",
                          Approx_Equal (Real (T_ISS), 5520.0, 100.0));
      end;

      Period := Orbital_Period (R_GEO, Mu_Earth);
      Runner.Run_Test ("GEO orbital period (~86400 s)",
                       Approx_Equal (Real (Period), 86164.0, 100.0));

      Runner.End_Suite;
   end Test_Twobody;

   procedure Test_Elements is
      R, V : Vector_3D;
      Elements : Orbital_Elements;
   begin
      Runner.Start_Suite ("Orbital Elements");

      R := (7000.0, 0.0, 0.0);
      declare
         V_Circ : constant Velocity_Km_S := Circular_Velocity (7000.0, Mu_Earth);
      begin
         V := (0.0, Real (V_Circ), 0.0);
      end;

      Elements := State_To_Elements (R, V, Mu_Earth);

      Runner.Run_Test ("Circular orbit eccentricity near zero",
                       Elements.Eccentricity < 0.001);

      Runner.Run_Test ("Equatorial orbit inclination near zero",
                       abs (Real (Elements.Inclination)) < 0.001);

      Runner.Run_Test ("Semi-major axis equals radius for circular",
                       Approx_Equal (Real (Elements.Semi_Major_Axis), 7000.0, 1.0));

      Runner.End_Suite;
   end Test_Elements;

   procedure Test_Kepler is
      E_Anom : Angle_Radians;
      M : Angle_Radians;
   begin
      Runner.Start_Suite ("Kepler Solvers");

      M := Angle_Radians (Pi / 3.0);
      E_Anom := Solve_Kepler_Elliptic (M, 0.0);
      Runner.Run_Test ("Kepler for circular (e=0)",
                       Approx_Equal (Real (E_Anom), Real (M), 1.0e-10));

      M := Angle_Radians (Pi / 4.0);
      E_Anom := Solve_Kepler_Elliptic (M, 0.5);
      declare
         M_Check : constant Real := Real (E_Anom) - 0.5 * Sin (Real (E_Anom));
      begin
         Runner.Run_Test ("Kepler for e=0.5",
                          Approx_Equal (M_Check, Real (M), 1.0e-10));
      end;

      Runner.Run_Test ("Stumpff C(0) = 1/2",
                       Approx_Equal (Stumpff_C (0.0), 0.5, 1.0e-10));
      Runner.Run_Test ("Stumpff S(0) = 1/6",
                       Approx_Equal (Stumpff_S (0.0), 1.0 / 6.0, 1.0e-10));

      Runner.End_Suite;
   end Test_Kepler;

   procedure Test_Maneuvers is
      Result : Hohmann_Result;
   begin
      Runner.Start_Suite ("Orbital Maneuvers (Hale Validation)");

      declare
         R_LEO : constant Distance_Km := Distance_Km (Real (R_Earth) + 200.0);
         R_GEO_Val : constant Distance_Km := 42164.0;
      begin
         Result := Hohmann_Transfer (R_LEO, R_GEO_Val, Mu_Earth);

         Runner.Run_Test ("Hale 6-1: Hohmann LEO-GEO Delta-V1 (2.457 km/s)",
                          Approx_Equal (Real (Result.Delta_V1), 2.457, 0.01));

         Runner.Run_Test ("Hale 6-1: Hohmann LEO-GEO Delta-V2 (1.478 km/s)",
                          Approx_Equal (Real (Result.Delta_V2), 1.478, 0.01));

         Runner.Run_Test ("Hale 6-1: Hohmann LEO-GEO Total (3.935 km/s)",
                          Approx_Equal (Real (Result.Total_Delta_V), 3.935, 0.01));
      end;

      Runner.Run_Test ("Bielliptic threshold: ratio < 11.94",
                       not Bielliptic_Is_Efficient (6578.0, 70000.0));

      Runner.Run_Test ("Bielliptic threshold: ratio > 11.94",
                       Bielliptic_Is_Efficient (6578.0, 100000.0));

      Runner.End_Suite;
   end Test_Maneuvers;

   procedure Test_Threebody is
      LP : Lagrange_Result;
      Stability : Stability_Result;
   begin
      Runner.Start_Suite ("Three-Body Dynamics");

      LP := Compute_Lagrange_Point (Earth_Moon_System, L1);
      Runner.Run_Test ("Earth-Moon L1 X coordinate",
                       LP.X > 0.0 and LP.X < 1.0);

      Runner.Run_Test ("Earth-Moon L1 Y coordinate (on axis)",
                       Approx_Equal (LP.Y, 0.0, 1.0e-10));

      LP := Compute_Lagrange_Point (Earth_Moon_System, L4);
      Runner.Run_Test ("Earth-Moon L4 Y coordinate (positive)",
                       LP.Y > 0.0);
      Runner.Run_Test ("Earth-Moon L4 is equilateral",
                       Approx_Equal (LP.Y, Sqrt (3.0) / 2.0, 0.01));

      Stability := Analyze_Stability (Earth_Moon_System, L4);
      Runner.Run_Test ("Earth-Moon L4 is stable",
                       Stability.Is_Stable);

      Stability := Analyze_Stability (Earth_Moon_System, L1);
      Runner.Run_Test ("Earth-Moon L1 is unstable",
                       not Stability.Is_Stable);

      Runner.End_Suite;
   end Test_Threebody;

   procedure Test_Propagation is
   begin
      Runner.Start_Suite ("Numerical Propagation");

      declare
         R_Val : constant Real := Real (R_Earth) + 400.0;
         V_Circ : constant Velocity_Km_S := Circular_Velocity (Distance_Km (R_Val), Mu_Earth);
         Initial_State : constant State_Vector := (
            Position => (R_Val, 0.0, 0.0),
            Velocity => (0.0, Real (V_Circ), 0.0)
         );
         Period : constant Time_Seconds := Orbital_Period (Distance_Km (R_Val), Mu_Earth);
         Model : constant Two_Body_Model := (Mu => Mu_Earth);
         Final_State : constant State_Vector :=
            Propagate_RK4 (Initial_State, 0.0, Period, 10.0, Model);
         E_Error : constant Real := Energy_Error (Initial_State, Final_State, Mu_Earth);
      begin
         Runner.Run_Test ("RK4 energy conservation (error < 1e-8)",
                          abs (E_Error) < 1.0e-8);

         Runner.Run_Test ("RK4 orbit closure position X",
                          Approx_Equal (Final_State.Position (1), Initial_State.Position (1), 10.0));
      end;

      declare
         R_Peri : constant Real := Real (R_Earth) + 300.0;
         A_Val : constant Real := Real (R_Earth) + 1000.0;
         V_Peri : constant Real := Sqrt (Real (Mu_Earth) * (2.0 / R_Peri - 1.0 / A_Val));
         Initial_State : constant State_Vector := (
            Position => (R_Peri, 0.0, 0.0),
            Velocity => (0.0, V_Peri, 0.0)
         );
         Period : constant Time_Seconds :=
            Time_Seconds (Two_Pi * Sqrt (A_Val ** 3 / Real (Mu_Earth)));
         Model : constant Two_Body_Model := (Mu => Mu_Earth);
         Final_State : constant State_Vector :=
            Propagate_RK78 (Initial_State, 0.0, Period, 1.0e-12, Model);
         E_Error : constant Real := Energy_Error (Initial_State, Final_State, Mu_Earth);
      begin
         Runner.Run_Test ("RK78 energy conservation (error < 1e-10)",
                          abs (E_Error) < 1.0e-10);
      end;

      --  Embedded integrator validation (B2): real DP54 (Dormand-Prince 5(4))
      --  and RKF78 (Fehlberg 7(8)) vs the analytic Kepler propagator,
      --  observed convergence order, step-controller and task-pool checks.
      --  Mirrors the equivalent tests in run_tests.adb.
      declare
         Model : constant Two_Body_Model := (Mu => Mu_Earth);

         R_Circ : constant Real := Real (R_Earth) + 500.0;
         V_Circ : constant Velocity_Km_S :=
            Circular_Velocity (Distance_Km (R_Circ), Mu_Earth);
         S_Circ : constant State_Vector := (Position => (R_Circ, 0.0, 0.0),
                                            Velocity => (0.0, Real (V_Circ), 0.0));
         P_Circ : constant Time_Seconds :=
            Orbital_Period (Distance_Km (R_Circ), Mu_Earth);

         A_Ecc  : constant Real := 26_600.0;
         E_Ecc  : constant Real := 0.7;
         R_Peri : constant Real := A_Ecc * (1.0 - E_Ecc);
         V_Peri : constant Real :=
            Sqrt (Real (Mu_Earth) * (2.0 / R_Peri - 1.0 / A_Ecc));
         S_Ecc  : constant State_Vector := (Position => (R_Peri, 0.0, 0.0),
                                            Velocity => (0.0, V_Peri, 0.0));
         P_Ecc  : constant Time_Seconds :=
            Time_Seconds (Two_Pi * Sqrt (A_Ecc ** 3 / Real (Mu_Earth)));

         --  Fixed-step terminal position error vs analytic Kepler; fixed
         --  stepping via Min_Step = Max_Step = h in the adaptive drivers
         function Fixed_Step_Error (Use_DP54 : Boolean;
                                    S0       : State_Vector;
                                    Period   : Time_Seconds;
                                    N_Steps  : Positive) return Real is
            H : constant Real := Real (Period) / Real (N_Steps);
            Config : constant Propagator_Config :=
               (Step_Size => Time_Seconds (H),
                Tolerance => 1.0,
                Min_Step  => Time_Seconds (H),
                Max_Step  => Time_Seconds (H),
                Max_Steps => 10 * N_Steps + 100);
            R_Ref  : Position_Vector;
            V_Ref  : Velocity_Vector;
            Result : Propagation_Result;
         begin
            Propagate (S0.Position, S0.Velocity, Period, Mu_Earth, R_Ref, V_Ref);
            if Use_DP54 then
               Result := Propagate_DP54 (S0, 0.0, Period, Config, Model);
            else
               Result := Propagate_RK78 (S0, 0.0, Period, Config, Model);
            end if;
            return Magnitude (Result.Final_State.Position - R_Ref);
         end Fixed_Step_Error;

      begin
         --  One-period terminal accuracy vs analytic Kepler at tol 1e-12
         declare
            R_Ref : Position_Vector;
            V_Ref : Velocity_Vector;
            F_DP54 : constant State_Vector :=
               Propagate_DP54 (S_Circ, 0.0, P_Circ, 1.0e-12, Model);
            F_RKF78 : constant State_Vector :=
               Propagate_RK78 (S_Circ, 0.0, P_Circ, 1.0e-12, Model);
         begin
            Propagate (S_Circ.Position, S_Circ.Velocity, P_Circ, Mu_Earth,
                       R_Ref, V_Ref);
            Runner.Run_Test ("DP54 circular vs Kepler analytic (pos err < 1e-4 km)",
                             Magnitude (F_DP54.Position - R_Ref) < 1.0e-4);
            Runner.Run_Test ("DP54 circular energy drift < 1e-9",
                             abs (Energy_Error (S_Circ, F_DP54, Mu_Earth)) < 1.0e-9);
            Runner.Run_Test ("RKF78 circular vs Kepler analytic (pos err < 1e-4 km)",
                             Magnitude (F_RKF78.Position - R_Ref) < 1.0e-4);
            Runner.Run_Test ("RKF78 circular energy drift < 1e-10",
                             abs (Energy_Error (S_Circ, F_RKF78, Mu_Earth)) < 1.0e-10);
         end;

         declare
            R_Ref : Position_Vector;
            V_Ref : Velocity_Vector;
            F_DP54 : constant State_Vector :=
               Propagate_DP54 (S_Ecc, 0.0, P_Ecc, 1.0e-12, Model);
            F_RKF78 : constant State_Vector :=
               Propagate_RK78 (S_Ecc, 0.0, P_Ecc, 1.0e-12, Model);
         begin
            Propagate (S_Ecc.Position, S_Ecc.Velocity, P_Ecc, Mu_Earth,
                       R_Ref, V_Ref);
            Runner.Run_Test ("DP54 eccentric e=0.7 vs Kepler (pos err < 1e-4 km)",
                             Magnitude (F_DP54.Position - R_Ref) < 1.0e-4);
            Runner.Run_Test ("DP54 eccentric energy drift < 1e-9",
                             abs (Energy_Error (S_Ecc, F_DP54, Mu_Earth)) < 1.0e-9);
            Runner.Run_Test ("RKF78 eccentric e=0.7 vs Kepler (pos err < 1e-4 km)",
                             Magnitude (F_RKF78.Position - R_Ref) < 1.0e-4);
            Runner.Run_Test ("RKF78 eccentric energy drift < 1e-10",
                             abs (Energy_Error (S_Ecc, F_RKF78, Mu_Earth)) < 1.0e-10);
         end;

         --  Observed convergence order via fixed steps h and h/2
         declare
            DP54_E1  : constant Real := Fixed_Step_Error (True, S_Circ, P_Circ, 400);
            DP54_E2  : constant Real := Fixed_Step_Error (True, S_Circ, P_Circ, 800);
            RKF78_E1 : constant Real := Fixed_Step_Error (False, S_Circ, P_Circ, 40);
            RKF78_E2 : constant Real := Fixed_Step_Error (False, S_Circ, P_Circ, 80);
            DP54_Order  : constant Real := Log (DP54_E1 / DP54_E2) / Log (2.0);
            RKF78_Order : constant Real := Log (RKF78_E1 / RKF78_E2) / Log (2.0);
         begin
            Runner.Run_Test ("DP54 observed convergence order >= 4.5",
                             DP54_E2 > 0.0 and then DP54_Order >= 4.5);
            Runner.Run_Test ("RKF78 observed convergence order >= 6.5",
                             RKF78_E2 > 0.0 and then RKF78_Order >= 6.5);
         end;

         --  Step-controller sanity: adaptive beats equal-accuracy fixed run
         declare
            N_Fixed  : constant Positive := 2_000;
            Adaptive : constant Propagation_Result :=
               Propagate_RK78 (S_Ecc, 0.0, P_Ecc, Default_Config, Model);
            Fixed_Err : constant Real :=
               Fixed_Step_Error (False, S_Ecc, P_Ecc, N_Fixed);
            R_Ref : Position_Vector;
            V_Ref : Velocity_Vector;
            Adaptive_Err : Real;
         begin
            Propagate (S_Ecc.Position, S_Ecc.Velocity, P_Ecc, Mu_Earth,
                       R_Ref, V_Ref);
            Adaptive_Err := Magnitude (Adaptive.Final_State.Position - R_Ref);
            Runner.Run_Test ("RKF78 adaptive beats equal-accuracy fixed step",
                             Adaptive.Success and then Fixed_Err <= Adaptive_Err
                             and then Adaptive.Steps_Used < N_Fixed / 4);
         end;

         --  Task-pool parallel propagation: parity and exception re-raise
         declare
            Samples   : State_Array (1 .. 6);
            Par       : State_Array (1 .. 6);
            Seq       : State_Vector;
            All_Match : Boolean := True;
         begin
            for I in Samples'Range loop
               declare
                  R_I : constant Real := R_Circ + Real (I) * 25.0;
                  V_I : constant Velocity_Km_S :=
                     Circular_Velocity (Distance_Km (R_I), Mu_Earth);
               begin
                  Samples (I) := (Position => (R_I, 0.0, 0.0),
                                  Velocity => (0.0, Real (V_I), 0.0));
               end;
            end loop;
            Par := Propagate_Parallel (Samples, 0.0, 5400.0, 1.0e-12, Model);
            for I in Samples'Range loop
               Seq := Propagate_RK78 (Samples (I), 0.0, 5400.0, 1.0e-12, Model);
               if Magnitude (Par (I).Position - Seq.Position) > 1.0e-9 or else
                  Magnitude (Par (I).Velocity - Seq.Velocity) > 1.0e-12
               then
                  All_Match := False;
               end if;
            end loop;
            Runner.Run_Test ("Parallel task pool matches sequential RK78",
                             All_Match);
         end;

         declare
            Bad    : State_Array (1 .. 5) := (others => S_Circ);
            Raised : Boolean := False;
         begin
            Bad (3).Position := (1.0e-12, 0.0, 0.0);
            declare
               Dummy : State_Array (1 .. 5);
            begin
               Dummy := Propagate_Parallel (Bad, 0.0, 100.0, 1.0e-10, Model);
               Raised := Dummy'Length /= 5;  -- Unreachable; references Dummy
            exception
               when others =>
                  Raised := True;
            end;
            Runner.Run_Test ("Parallel task pool re-raises worker exception",
                             Raised);
         end;
      end;

      Runner.End_Suite;
   end Test_Propagation;

   ---------------------------------------------------------------------------
   -- Main Entry Point
   ---------------------------------------------------------------------------

   Verbose : Boolean := False;

begin
   --  Parse command line for verbose flag
   for I in 1 .. CLI.Argument_Count loop
      if CLI.Argument (I) = "-v" or CLI.Argument (I) = "--verbose" then
         Verbose := True;
      end if;
   end loop;

   IO.Put_Line ("=========================================");
   IO.Put_Line ("  HALE Orbital Mechanics - Full Test Suite");
   IO.Put_Line ("  Target: 150+ tests (ISS-001)");
   IO.Put_Line ("=========================================");
   IO.New_Line;

   Runner.Reset;

   --  Core functionality tests
   IO.Put_Line ("=== CORE FUNCTIONALITY TESTS ===");
   IO.New_Line;
   Test_Vectors;
   Test_Matrices;
   Test_Twobody;
   Test_Elements;
   Test_Kepler;
   Test_Maneuvers;
   Test_Threebody;
   Test_Propagation;

   --  Edge case tests for numerical robustness
   IO.Put_Line ("=== EDGE CASE TESTS ===");
   IO.New_Line;
   Hale_Tests.Edge_Cases.Run_All_Edge_Case_Tests;

   --  Vallado validation tests
   IO.Put_Line ("=== VALLADO VALIDATION TESTS ===");
   IO.New_Line;
   Hale_Tests.Vallado.Run_All_Vallado_Tests;

   --  Lambert multi-revolution tests (ISS-030)
   IO.Put_Line ("=== LAMBERT MULTI-REVOLUTION TESTS ===");
   IO.New_Line;
   Hale_Tests.Lambert_MultiRev.Run_All_Lambert_MultiRev_Tests;

   --  Determinism tests (ISS-024)
   IO.Put_Line ("=== DETERMINISM TESTS ===");
   IO.New_Line;
   Hale_Tests.Determinism.Run_All_Determinism_Tests;

   --  Integration tests (ISS-037)
   IO.Put_Line ("=== INTEGRATION TESTS ===");
   IO.New_Line;
   Hale_Tests.Integration.Run_All_Integration_Tests;

   --  Parallel propagation tests (ISS-031)
   IO.Put_Line ("=== PARALLEL PROPAGATION TESTS ===");
   IO.New_Line;
   Hale_Tests.Parallel.Run_All_Parallel_Tests;

   --  Periodic orbit tests (ISS-034)
   IO.Put_Line ("=== PERIODIC ORBIT TESTS ===");
   IO.New_Line;
   Hale_Tests.Periodic_Orbits.Run_All_Periodic_Orbit_Tests;

   --  Python oracle cross-validation (reference CSVs under validation/data)
   IO.New_Line;
   IO.Put_Line ("=== PYTHON ORACLE CROSS-VALIDATION ===");
   IO.New_Line;
   Hale_Tests.Oracle.Run_All_Oracle_Tests;

   --  Print final summary
   IO.New_Line;
   Runner.Print_Summary;

   --  Exit with appropriate code
   if Runner.Tests_Failed > 0 then
      CLI.Set_Exit_Status (CLI.Failure);
   else
      CLI.Set_Exit_Status (CLI.Success);
   end if;

end Run_All_Tests;
