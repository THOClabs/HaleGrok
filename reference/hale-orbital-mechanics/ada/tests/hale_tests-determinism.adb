-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Floating-Point Determinism Tests Implementation
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Tests.Runner; use Hale_Tests.Runner;
with Hale_Orbital.Types;      use Hale_Orbital.Types;
with Hale_Orbital.Constants;  use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;    use Hale_Orbital.Vectors;
with Hale_Orbital.Twobody;    use Hale_Orbital.Twobody;
with Hale_Orbital.Maneuvers;  use Hale_Orbital.Maneuvers;
with Hale_Orbital.Kepler;     use Hale_Orbital.Kepler;
with Hale_Orbital.Lambert;    use Hale_Orbital.Lambert;
with Hale_Orbital.Propagation; use Hale_Orbital.Propagation;

package body Hale_Tests.Determinism is

   package IO renames Ada.Text_IO;
   package Real_Funcs is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Funcs;

   --  Tolerance for cross-platform validation (relaxed)
   Cross_Platform_Tolerance : constant Real := 1.0e-10;

   --  Reference values computed on Linux x86_64, GNAT, deterministic mode
   --  These serve as canonical values for cross-platform comparison

   --  Hohmann LEO (200km) to GEO transfer
   Ref_Hohmann_DV1 : constant Real := 2.457;      -- km/s (±0.001)
   Ref_Hohmann_DV2 : constant Real := 1.478;      -- km/s (±0.001)
   Ref_Hohmann_Total : constant Real := 3.935;    -- km/s (±0.001)

   --  Kepler solution: e=0.5, M=Pi/4
   --  Solves E - 0.5*sin(E) = Pi/4; value recomputed independently by
   --  Newton iteration to 1e-12 (the previous stored value, 0.652358139,
   --  was never validated — this suite was unreachable from any build).
   Ref_Kepler_E : constant Real := 1.261_703_055_253; -- radians (±1e-9)

   --  Stumpff functions at z=1.0
   Ref_Stumpff_C_1 : constant Real := 0.459_697_694; -- (±1e-8)
   Ref_Stumpff_S_1 : constant Real := 0.158_529_015; -- (±1e-8)

   --  Circular velocity at R_Earth
   Ref_V_Circ_Earth : constant Real := 7.905;     -- km/s (±0.001)

   function Approx_Equal (A, B : Real; Tol : Real := 1.0e-10) return Boolean is
   begin
      return abs (A - B) < Tol;
   end Approx_Equal;

   ---------------------------------------------------------------------------
   -- Test Calculation Repeatability
   ---------------------------------------------------------------------------

   procedure Test_Calculation_Repeatability is
   begin
      Start_Suite ("Calculation Repeatability (Same-Platform Determinism)");

      --  Test 1: Hohmann transfer computed twice must be identical
      declare
         R_LEO : constant Distance_Km := Distance_Km (Real (R_Earth) + 200.0);
         R_GEO_Val : constant Distance_Km := 42164.0;
         Result1 : constant Hohmann_Result := Hohmann_Transfer (R_LEO, R_GEO_Val, Mu_Earth);
         Result2 : constant Hohmann_Result := Hohmann_Transfer (R_LEO, R_GEO_Val, Mu_Earth);
      begin
         Run_Test ("Hohmann DV1 repeatable",
                   Real (Result1.Delta_V1) = Real (Result2.Delta_V1));
         Run_Test ("Hohmann DV2 repeatable",
                   Real (Result1.Delta_V2) = Real (Result2.Delta_V2));
         Run_Test ("Hohmann Total repeatable",
                   Real (Result1.Total_Delta_V) = Real (Result2.Total_Delta_V));
      end;

      --  Test 2: Kepler solver must be repeatable
      declare
         M : constant Angle_Radians := Angle_Radians (Pi / 4.0);
         E1 : constant Angle_Radians := Solve_Kepler_Elliptic (M, 0.5);
         E2 : constant Angle_Radians := Solve_Kepler_Elliptic (M, 0.5);
      begin
         Run_Test ("Kepler solution repeatable",
                   Real (E1) = Real (E2));
      end;

      --  Test 3: Propagation must be repeatable
      declare
         R_Val : constant Real := Real (R_Earth) + 400.0;
         V_Circ : constant Velocity_Km_S := Circular_Velocity (Distance_Km (R_Val), Mu_Earth);
         Initial : constant State_Vector := (
            Position => (R_Val, 0.0, 0.0),
            Velocity => (0.0, Real (V_Circ), 0.0)
         );
         Model : constant Two_Body_Model := (Mu => Mu_Earth);
         Final1 : constant State_Vector := Propagate_RK4 (Initial, 0.0, 3600.0, 10.0, Model);
         Final2 : constant State_Vector := Propagate_RK4 (Initial, 0.0, 3600.0, 10.0, Model);
      begin
         Run_Test ("Propagation position X repeatable",
                   Final1.Position (1) = Final2.Position (1));
         Run_Test ("Propagation position Y repeatable",
                   Final1.Position (2) = Final2.Position (2));
         Run_Test ("Propagation velocity X repeatable",
                   Final1.Velocity (1) = Final2.Velocity (1));
      end;

      --  Test 4: Vector operations repeatable
      declare
         V1 : constant Vector_3D := (1.234567890123456, 2.345678901234567, 3.456789012345678);
         V2 : constant Vector_3D := (4.567890123456789, 5.678901234567890, 6.789012345678901);
         Dot1 : constant Real := Dot (V1, V2);
         Dot2 : constant Real := Dot (V1, V2);
         Cross1 : constant Vector_3D := Cross (V1, V2);
         Cross2 : constant Vector_3D := Cross (V1, V2);
      begin
         Run_Test ("Dot product repeatable", Dot1 = Dot2);
         Run_Test ("Cross product X repeatable", Cross1 (1) = Cross2 (1));
         Run_Test ("Cross product Y repeatable", Cross1 (2) = Cross2 (2));
         Run_Test ("Cross product Z repeatable", Cross1 (3) = Cross2 (3));
      end;

      --  Test 5: Stumpff functions repeatable
      declare
         C1 : constant Real := Stumpff_C (1.0);
         C2 : constant Real := Stumpff_C (1.0);
         S1 : constant Real := Stumpff_S (1.0);
         S2 : constant Real := Stumpff_S (1.0);
      begin
         Run_Test ("Stumpff C repeatable", C1 = C2);
         Run_Test ("Stumpff S repeatable", S1 = S2);
      end;

      End_Suite;
   end Test_Calculation_Repeatability;

   ---------------------------------------------------------------------------
   -- Test Summation Stability
   ---------------------------------------------------------------------------

   procedure Test_Summation_Stability is
      --  Tests for numerical stability in accumulation operations
   begin
      Start_Suite ("Summation Stability");

      --  Test: Order of operations shouldn't cause large differences
      declare
         Values : constant array (1 .. 10) of Real :=
            (1.0e10, 1.0, -1.0e10, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0);
         Sum_Forward : Real := 0.0;
         Sum_Reverse : Real := 0.0;
      begin
         for I in Values'Range loop
            Sum_Forward := Sum_Forward + Values (I);
         end loop;

         for I in reverse Values'Range loop
            Sum_Reverse := Sum_Reverse + Values (I);
         end loop;

         --  With catastrophic cancellation, these could differ significantly
         --  A reasonable tolerance allows for expected floating-point behavior
         Run_Test ("Forward/reverse sum within tolerance",
                   abs (Sum_Forward - Sum_Reverse) < 1.0e-5);
      end;

      --  Test: Small perturbations propagate predictably
      declare
         Base : constant Real := 1.0;
         Epsilon : constant Real := 1.0e-15;
         Result1 : constant Real := (Base + Epsilon) - Base;
         Result2 : constant Real := Epsilon;
      begin
         --  May not be exactly equal due to rounding, but should be close
         Run_Test ("Small perturbation preserved (within epsilon)",
                   abs (Result1 - Result2) < 1.0e-14);
      end;

      End_Suite;
   end Test_Summation_Stability;

   ---------------------------------------------------------------------------
   -- Generate Reference Values
   ---------------------------------------------------------------------------

   procedure Generate_Reference_Values is
   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Reference Values for Cross-Platform");
      IO.Put_Line ("  Validation (ISS-024)");
      IO.Put_Line ("=========================================");
      IO.New_Line;

      --  Hohmann transfer
      declare
         R_LEO : constant Distance_Km := Distance_Km (Real (R_Earth) + 200.0);
         R_GEO_Val : constant Distance_Km := 42164.0;
         Result : constant Hohmann_Result := Hohmann_Transfer (R_LEO, R_GEO_Val, Mu_Earth);
      begin
         IO.Put_Line ("Hohmann LEO-GEO Transfer:");
         IO.Put_Line ("  Delta-V1: " & Real'Image (Real (Result.Delta_V1)) & " km/s");
         IO.Put_Line ("  Delta-V2: " & Real'Image (Real (Result.Delta_V2)) & " km/s");
         IO.Put_Line ("  Total:    " & Real'Image (Real (Result.Total_Delta_V)) & " km/s");
         IO.New_Line;
      end;

      --  Kepler solver
      declare
         M : constant Angle_Radians := Angle_Radians (Pi / 4.0);
         E_Anom : constant Angle_Radians := Solve_Kepler_Elliptic (M, 0.5);
      begin
         IO.Put_Line ("Kepler Solver (e=0.5, M=Pi/4):");
         IO.Put_Line ("  E: " & Real'Image (Real (E_Anom)) & " rad");
         IO.New_Line;
      end;

      --  Stumpff functions
      IO.Put_Line ("Stumpff Functions:");
      IO.Put_Line ("  C(0.0): " & Real'Image (Stumpff_C (0.0)));
      IO.Put_Line ("  S(0.0): " & Real'Image (Stumpff_S (0.0)));
      IO.Put_Line ("  C(1.0): " & Real'Image (Stumpff_C (1.0)));
      IO.Put_Line ("  S(1.0): " & Real'Image (Stumpff_S (1.0)));
      IO.New_Line;

      --  Circular velocity
      declare
         V_Circ : constant Velocity_Km_S := Circular_Velocity (R_Earth, Mu_Earth);
      begin
         IO.Put_Line ("Circular Velocity at R_Earth:");
         IO.Put_Line ("  V_circ: " & Real'Image (Real (V_Circ)) & " km/s");
         IO.New_Line;
      end;

      --  Propagation reference
      declare
         R_Val : constant Real := Real (R_Earth) + 400.0;
         V_Circ : constant Velocity_Km_S := Circular_Velocity (Distance_Km (R_Val), Mu_Earth);
         Initial : constant State_Vector := (
            Position => (R_Val, 0.0, 0.0),
            Velocity => (0.0, Real (V_Circ), 0.0)
         );
         Model : constant Two_Body_Model := (Mu => Mu_Earth);
         Final : constant State_Vector := Propagate_RK4 (Initial, 0.0, 3600.0, 10.0, Model);
      begin
         IO.Put_Line ("Propagation (LEO, 1 hour, RK4):");
         IO.Put_Line ("  Final Position X: " & Real'Image (Final.Position (1)) & " km");
         IO.Put_Line ("  Final Position Y: " & Real'Image (Final.Position (2)) & " km");
         IO.Put_Line ("  Final Velocity X: " & Real'Image (Final.Velocity (1)) & " km/s");
         IO.Put_Line ("  Final Velocity Y: " & Real'Image (Final.Velocity (2)) & " km/s");
      end;

      IO.Put_Line ("=========================================");
   end Generate_Reference_Values;

   ---------------------------------------------------------------------------
   -- Test Against References
   ---------------------------------------------------------------------------

   procedure Test_Against_References is
   begin
      Start_Suite ("Cross-Platform Reference Validation");

      --  Hohmann transfer
      declare
         R_LEO : constant Distance_Km := Distance_Km (Real (R_Earth) + 200.0);
         R_GEO_Val : constant Distance_Km := 42164.0;
         Result : constant Hohmann_Result := Hohmann_Transfer (R_LEO, R_GEO_Val, Mu_Earth);
      begin
         Run_Test ("Hohmann DV1 matches reference",
                   Approx_Equal (Real (Result.Delta_V1), Ref_Hohmann_DV1, 0.01));
         Run_Test ("Hohmann DV2 matches reference",
                   Approx_Equal (Real (Result.Delta_V2), Ref_Hohmann_DV2, 0.01));
         Run_Test ("Hohmann Total matches reference",
                   Approx_Equal (Real (Result.Total_Delta_V), Ref_Hohmann_Total, 0.01));
      end;

      --  Kepler solver
      declare
         M : constant Angle_Radians := Angle_Radians (Pi / 4.0);
         E_Anom : constant Angle_Radians := Solve_Kepler_Elliptic (M, 0.5);
      begin
         Run_Test ("Kepler E matches reference",
                   Approx_Equal (Real (E_Anom), Ref_Kepler_E, 1.0e-6));
      end;

      --  Stumpff functions
      Run_Test ("Stumpff C(1) matches reference",
                Approx_Equal (Stumpff_C (1.0), Ref_Stumpff_C_1, 1.0e-6));
      Run_Test ("Stumpff S(1) matches reference",
                Approx_Equal (Stumpff_S (1.0), Ref_Stumpff_S_1, 1.0e-6));

      --  Circular velocity
      declare
         V_Circ : constant Velocity_Km_S := Circular_Velocity (R_Earth, Mu_Earth);
      begin
         Run_Test ("Circular velocity matches reference",
                   Approx_Equal (Real (V_Circ), Ref_V_Circ_Earth, 0.01));
      end;

      End_Suite;
   end Test_Against_References;

   ---------------------------------------------------------------------------
   -- Main Runner
   ---------------------------------------------------------------------------

   procedure Run_All_Determinism_Tests is
   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Floating-Point Determinism Tests");
      IO.Put_Line ("  (ISS-024)");
      IO.Put_Line ("=========================================");
      IO.New_Line;

      Test_Calculation_Repeatability;
      Test_Summation_Stability;
      Test_Against_References;
   end Run_All_Determinism_Tests;

end Hale_Tests.Determinism;
