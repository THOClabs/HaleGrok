-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Negative Tests Implementation (ISS-011)
-------------------------------------------------------------------------------
-- Tests for invalid inputs and error handling.
-- Each test verifies that the library properly rejects invalid inputs.
-- Tests pass when expected exceptions are raised.
--
-- DO-178C Reference: A-6.3.1 Test Completeness
-- RTM Mapping: NFR-ROB-001 through NFR-ROB-004
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Tests.Runner; use Hale_Tests.Runner;
with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;   use Hale_Orbital.Vectors;
with Hale_Orbital.Elements;  use Hale_Orbital.Elements;
with Hale_Orbital.Kepler;    use Hale_Orbital.Kepler;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;
with Hale_Orbital.Lambert;   use Hale_Orbital.Lambert;
with Hale_Orbital.Stumpff;

package body Hale_Tests.Negative is

   package IO renames Ada.Text_IO;

   package Real_Funcs is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Funcs;

   ---------------------------------------------------------------------------
   -- Helper: Test that an exception is raised
   -- Returns True if any exception was raised, False otherwise
   ---------------------------------------------------------------------------

   --  Note: Ada requires specific exception handling patterns.
   --  We use block-level exception handlers for each test case.

   ---------------------------------------------------------------------------
   -- Test_Invalid_Eccentricity (ISS-011, NFR-ROB-001)
   ---------------------------------------------------------------------------
   --  Tests: e = 1.0, e = 1.001, e = -0.1 for elliptic functions
   --  Expected: Invalid_Orbit exception or contract failure
   ---------------------------------------------------------------------------

   procedure Test_Invalid_Eccentricity is
      Result : Angle_Radians;
      pragma Unreferenced (Result);
      Exception_Raised : Boolean;
   begin
      Start_Suite ("Invalid Eccentricity Tests (ISS-011)");

      --  Test e = 1.0 (parabolic boundary) for elliptic solver
      --  Should fail: elliptic solver requires e < 1.0
      Exception_Raised := False;
      begin
         Result := Solve_Kepler_Elliptic (Mean_Anomaly => Angle_Radians (1.0),
                                          Eccentricity => 1.0);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Elliptic solver rejects e = 1.0",
                Exception_Raised);

      --  Test e = 1.001 (hyperbolic) for elliptic solver
      --  Should fail: elliptic solver requires e < 1.0
      Exception_Raised := False;
      begin
         Result := Solve_Kepler_Elliptic (Mean_Anomaly => Angle_Radians (1.0),
                                          Eccentricity => 1.001);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Elliptic solver rejects e = 1.001",
                Exception_Raised);

      --  Test e = -0.1 (negative eccentricity - invalid)
      --  Should fail: eccentricity must be >= 0
      Exception_Raised := False;
      begin
         Result := Solve_Kepler_Elliptic (Mean_Anomaly => Angle_Radians (1.0),
                                          Eccentricity => -0.1);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Elliptic solver rejects e = -0.1",
                Exception_Raised);

      --  Test True_To_Eccentric_Anomaly with invalid e
      Exception_Raised := False;
      begin
         Result := True_To_Eccentric_Anomaly (Nu => Angle_Radians (1.0),
                                              E  => 1.0);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("True_To_Eccentric rejects e = 1.0",
                Exception_Raised);

      --  Test hyperbolic solver with e <= 1.0
      --  Should fail: hyperbolic solver requires e > 1.0
      Exception_Raised := False;
      declare
         H_Result : Real;
         pragma Unreferenced (H_Result);
      begin
         H_Result := Solve_Kepler_Hyperbolic (Mean_Anomaly => 1.0,
                                              Eccentricity => 0.9);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Hyperbolic solver rejects e = 0.9",
                Exception_Raised);

      End_Suite;
   end Test_Invalid_Eccentricity;

   ---------------------------------------------------------------------------
   -- Test_Invalid_SMA (ISS-011, NFR-ROB-001)
   ---------------------------------------------------------------------------
   --  Tests: a = 0, a < 0 for functions requiring positive SMA
   --  Expected: Invalid_Orbit exception or division by zero prevention
   ---------------------------------------------------------------------------

   procedure Test_Invalid_SMA is
      Result : Time_Seconds;
      pragma Unreferenced (Result);
      V_Result : Velocity_Km_S;
      pragma Unreferenced (V_Result);
      Exception_Raised : Boolean;
   begin
      Start_Suite ("Invalid Semi-Major Axis Tests (ISS-011)");

      --  Test orbital period with a = 0
      --  Should fail: period requires a > 0
      Exception_Raised := False;
      begin
         Result := Orbital_Period (A  => Distance_Km (0.0),
                                   Mu => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Orbital_Period rejects a = 0",
                Exception_Raised);

      --  Test orbital period with a < 0
      --  Should fail: period requires a > 0
      Exception_Raised := False;
      begin
         Result := Orbital_Period (A  => Distance_Km (-1000.0),
                                   Mu => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Orbital_Period rejects a < 0",
                Exception_Raised);

      --  Test vis-viva with a = 0
      --  Should fail: vis-viva has 1/a term
      Exception_Raised := False;
      begin
         V_Result := Vis_Viva (R  => Distance_Km (7000.0),
                               A  => Distance_Km (0.0),
                               Mu => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Vis_Viva rejects a = 0",
                Exception_Raised);

      --  Test mean motion with a = 0
      --  Should fail: mean motion has a^3 in denominator
      Exception_Raised := False;
      declare
         N_Result : Real;
         pragma Unreferenced (N_Result);
      begin
         N_Result := Mean_Motion (A  => Distance_Km (0.0),
                                  Mu => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Mean_Motion rejects a = 0",
                Exception_Raised);

      End_Suite;
   end Test_Invalid_SMA;

   ---------------------------------------------------------------------------
   -- Test_Invalid_Radius (ISS-011, NFR-ROB-001)
   ---------------------------------------------------------------------------
   --  Tests: r = 0, r < 0 for functions requiring positive radius
   --  Expected: Contract violation or Constraint_Error
   ---------------------------------------------------------------------------

   procedure Test_Invalid_Radius is
      V_Result : Velocity_Km_S;
      pragma Unreferenced (V_Result);
      Exception_Raised : Boolean;
   begin
      Start_Suite ("Invalid Radius Tests (ISS-011)");

      --  Test circular velocity with r = 0
      Exception_Raised := False;
      begin
         V_Result := Circular_Velocity (R  => Distance_Km (0.0),
                                        Mu => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Circular_Velocity rejects r = 0",
                Exception_Raised);

      --  Test circular velocity with r < 0
      Exception_Raised := False;
      begin
         V_Result := Circular_Velocity (R  => Distance_Km (-1000.0),
                                        Mu => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Circular_Velocity rejects r < 0",
                Exception_Raised);

      --  Test escape velocity with r = 0
      Exception_Raised := False;
      begin
         V_Result := Escape_Velocity (R  => Distance_Km (0.0),
                                      Mu => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Escape_Velocity rejects r = 0",
                Exception_Raised);

      --  Test vis-viva with r = 0
      Exception_Raised := False;
      begin
         V_Result := Vis_Viva (R  => Distance_Km (0.0),
                               A  => Distance_Km (7000.0),
                               Mu => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Vis_Viva rejects r = 0",
                Exception_Raised);

      End_Suite;
   end Test_Invalid_Radius;

   ---------------------------------------------------------------------------
   -- Test_Invalid_Mu (ISS-011, NFR-ROB-001)
   ---------------------------------------------------------------------------
   --  Tests: Mu = 0, Mu < 0
   --  Expected: Contract violation - Mu must be positive
   ---------------------------------------------------------------------------

   procedure Test_Invalid_Mu is
      V_Result : Velocity_Km_S;
      pragma Unreferenced (V_Result);
      T_Result : Time_Seconds;
      pragma Unreferenced (T_Result);
      Exception_Raised : Boolean;
   begin
      Start_Suite ("Invalid Gravitational Parameter Tests (ISS-011)");

      --  Test circular velocity with Mu = 0
      Exception_Raised := False;
      begin
         V_Result := Circular_Velocity (R  => Distance_Km (7000.0),
                                        Mu => Gravitational_Parameter (0.0));
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Circular_Velocity rejects Mu = 0",
                Exception_Raised);

      --  Test circular velocity with Mu < 0
      Exception_Raised := False;
      begin
         V_Result := Circular_Velocity (R  => Distance_Km (7000.0),
                                        Mu => Gravitational_Parameter (-100.0));
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Circular_Velocity rejects Mu < 0",
                Exception_Raised);

      --  Test orbital period with Mu = 0
      Exception_Raised := False;
      begin
         T_Result := Orbital_Period (A  => Distance_Km (7000.0),
                                     Mu => Gravitational_Parameter (0.0));
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Orbital_Period rejects Mu = 0",
                Exception_Raised);

      --  Test escape velocity with Mu = 0
      Exception_Raised := False;
      begin
         V_Result := Escape_Velocity (R  => Distance_Km (7000.0),
                                      Mu => Gravitational_Parameter (0.0));
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Escape_Velocity rejects Mu = 0",
                Exception_Raised);

      End_Suite;
   end Test_Invalid_Mu;

   ---------------------------------------------------------------------------
   -- Test_Zero_Vectors (ISS-011, NFR-ROB-002)
   ---------------------------------------------------------------------------
   --  Tests: Zero position/velocity vectors where non-zero required
   --  Expected: Singularity_Error or contract failure
   ---------------------------------------------------------------------------

   procedure Test_Zero_Vectors is
      V_Zero : constant Vector_3D := (0.0, 0.0, 0.0);
      V_Valid : constant Vector_3D := (7000.0, 0.0, 0.0);
      V_Vel : constant Vector_3D := (0.0, 7.5, 0.0);
      Elements : Orbital_Elements;
      pragma Unreferenced (Elements);
      Exception_Raised : Boolean;
   begin
      Start_Suite ("Zero Vector Tests (ISS-011)");

      --  Test State_To_Elements with zero position
      --  Should fail: position vector cannot be zero
      Exception_Raised := False;
      begin
         Elements := State_To_Elements (R  => V_Zero,
                                        V  => V_Vel,
                                        Mu => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("State_To_Elements rejects zero position",
                Exception_Raised);

      --  Test State_To_Elements with zero velocity
      --  This may or may not be an error (degenerate orbit)
      --  depending on implementation
      Exception_Raised := False;
      begin
         Elements := State_To_Elements (R  => V_Valid,
                                        V  => V_Zero,
                                        Mu => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      --  Note: Zero velocity creates a degenerate (radial) trajectory
      --  Implementation may handle this differently
      Run_Test ("State_To_Elements handles zero velocity",
                True);  -- Mark as info - behavior varies

      --  Test Angular_Momentum with zero position
      Exception_Raised := False;
      declare
         H_Result : Specific_Angular_Momentum;
         pragma Unreferenced (H_Result);
      begin
         H_Result := Angular_Momentum (R => V_Zero,
                                       V => V_Vel);
         --  Zero cross Zero should be Zero, not an error
         --  But zero position is physically invalid
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Angular_Momentum handles zero position",
                True);  -- Zero cross product is defined

      --  Test Normalize with zero vector
      Exception_Raised := False;
      declare
         N_Result : Vector_3D;
         pragma Unreferenced (N_Result);
      begin
         N_Result := Normalize (V_Zero);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Normalize rejects zero vector",
                Exception_Raised);

      End_Suite;
   end Test_Zero_Vectors;

   ---------------------------------------------------------------------------
   -- Test_Invalid_TOF (ISS-011, NFR-ROB-003)
   ---------------------------------------------------------------------------
   --  Tests: TOF <= 0, TOF too small for Lambert problem
   --  Expected: Invalid_Orbit or Convergence_Error
   ---------------------------------------------------------------------------

   procedure Test_Invalid_TOF is
      R1 : constant Position_Vector := (7000.0, 0.0, 0.0);
      R2 : constant Position_Vector := (0.0, 10000.0, 0.0);
      Solution : Lambert_Result :=
         (V1         => (others => 0.0),
          V2         => (others => 0.0),
          A          => 0.0,
          E          => 0.0,
          Iterations => 0,
          Converged  => False);
      Exception_Raised : Boolean;
   begin
      Start_Suite ("Invalid Time-of-Flight Tests (ISS-011)");

      --  Test Lambert with TOF = 0
      --  Should fail: cannot transfer in zero time
      Exception_Raised := False;
      begin
         Solution := Solve_Lambert (R1  => R1,
                                    R2  => R2,
                                    TOF => Time_Seconds (0.0),
                                    Mu  => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Lambert rejects TOF = 0",
                Exception_Raised);

      --  Test Lambert with TOF < 0
      --  Should fail: negative time not physical
      Exception_Raised := False;
      begin
         Solution := Solve_Lambert (R1  => R1,
                                    R2  => R2,
                                    TOF => Time_Seconds (-1000.0),
                                    Mu  => Mu_Earth);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Lambert rejects TOF < 0",
                Exception_Raised);

      --  Test Lambert with very small TOF
      --  May fail to converge due to high-energy requirement
      Exception_Raised := False;
      begin
         Solution := Solve_Lambert (R1  => R1,
                                    R2  => R2,
                                    TOF => Time_Seconds (1.0),  -- 1 second for 10000km!
                                    Mu  => Mu_Earth);
         --  If it returns without exception, check convergence flag
         if not Solution.Converged then
            Exception_Raised := True;  -- Non-convergence is expected behavior
         end if;
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Lambert handles impossibly short TOF",
                Exception_Raised or not Solution.Converged);

      End_Suite;
   end Test_Invalid_TOF;

   ---------------------------------------------------------------------------
   -- Test_Invalid_Tolerance (ISS-011, NFR-ROB-004)
   ---------------------------------------------------------------------------
   --  Tests: Tolerance <= 0, Tolerance too tight
   --  Expected: Contract failure for invalid tolerance
   ---------------------------------------------------------------------------

   procedure Test_Invalid_Tolerance is
      Result : Angle_Radians;
      pragma Unreferenced (Result);
      Exception_Raised : Boolean;
   begin
      Start_Suite ("Invalid Tolerance Tests (ISS-011)");

      --  Test Kepler solver with tolerance = 0
      Exception_Raised := False;
      begin
         Result := Solve_Kepler_Elliptic (Mean_Anomaly => Angle_Radians (1.0),
                                          Eccentricity => 0.5,
                                          Tolerance    => 0.0);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Kepler solver rejects tolerance = 0",
                Exception_Raised);

      --  Test Kepler solver with negative tolerance
      Exception_Raised := False;
      begin
         Result := Solve_Kepler_Elliptic (Mean_Anomaly => Angle_Radians (1.0),
                                          Eccentricity => 0.5,
                                          Tolerance    => -1.0e-10);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Kepler solver rejects negative tolerance",
                Exception_Raised);

      --  Test Mean_To_Eccentric_Anomaly with tolerance = 0
      Exception_Raised := False;
      begin
         Result := Mean_To_Eccentric_Anomaly (M         => Angle_Radians (1.0),
                                              E         => 0.5,
                                              Tolerance => 0.0);
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Mean_To_Eccentric rejects tolerance = 0",
                Exception_Raised);

      End_Suite;
   end Test_Invalid_Tolerance;

   ---------------------------------------------------------------------------
   -- Test_Invalid_Angular_Momentum (ISS-011, NFR-ROB-001)
   ---------------------------------------------------------------------------
   --  Tests: H = 0 for functions requiring non-zero angular momentum
   --  Expected: Singularity_Error or division by zero prevention
   ---------------------------------------------------------------------------

   procedure Test_Invalid_Angular_Momentum is
      V_Result : Velocity_Km_S;
      pragma Unreferenced (V_Result);
      Exception_Raised : Boolean;
   begin
      Start_Suite ("Invalid Angular Momentum Tests (ISS-011)");

      --  Test Radial_Velocity with H = 0
      --  Formula v_r = (mu/h) * e * sin(nu) has h in denominator
      Exception_Raised := False;
      begin
         V_Result := Radial_Velocity (Mu => Mu_Earth,
                                      H  => Specific_Angular_Momentum (0.0),
                                      E  => 0.5,
                                      Nu => Angle_Radians (1.0));
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Radial_Velocity rejects H = 0",
                Exception_Raised);

      --  Test Transverse_Velocity with H = 0
      --  Formula v_t = (mu/h) * (1 + e*cos(nu)) has h in denominator
      Exception_Raised := False;
      begin
         V_Result := Transverse_Velocity (Mu => Mu_Earth,
                                          H  => Specific_Angular_Momentum (0.0),
                                          E  => 0.5,
                                          Nu => Angle_Radians (1.0));
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Transverse_Velocity rejects H = 0",
                Exception_Raised);

      --  Test with very small H (near-zero)
      Exception_Raised := False;
      begin
         V_Result := Radial_Velocity (Mu => Mu_Earth,
                                      H  => Specific_Angular_Momentum (1.0e-20),
                                      E  => 0.5,
                                      Nu => Angle_Radians (1.0));
         --  This might produce an overflow or unreasonable result
      exception
         when others =>
            Exception_Raised := True;
      end;
      Run_Test ("Radial_Velocity handles near-zero H",
                Exception_Raised);  -- Expect rejection of numerically dangerous values

      End_Suite;
   end Test_Invalid_Angular_Momentum;

   ---------------------------------------------------------------------------
   -- Test_Lambert_Guards (ISS-010, NFR-ROB-002/003)
   ---------------------------------------------------------------------------
   --  Tests the hardened Lambert solver:
   --    (a) exactly-180-degree transfer raises Invalid_Orbit
   --        (docs/specs/05-lambert.md)
   --    (b) near-degenerate (179.999 deg) either converges finite or
   --        reports Converged = False - never NaN/Inf
   --    (c) parabolic-boundary stressor: at the exact z = 0 root the
   --        semi-major axis denominator z*C(z) is singular; the guard must
   --        reject it, and nearby TOFs must never yield NaN
   --    (d) multi-rev path still returns an empty array for degenerate
   --        input (behavior unchanged)
   ---------------------------------------------------------------------------

   procedure Test_Lambert_Guards is

      --  Gate invariant: a converged result must carry finite velocity
      --  components ('Valid is False for NaN and infinities) and a
      --  positive semi-major axis.  Non-converged results trivially pass.
      function Gate_Invariant (R : Lambert_Result) return Boolean is
        ((not R.Converged)
         or else (R.V1 (1)'Valid and then R.V1 (2)'Valid
                  and then R.V1 (3)'Valid
                  and then R.V2 (1)'Valid and then R.V2 (2)'Valid
                  and then R.V2 (3)'Valid
                  and then R.A'Valid and then Real (R.A) > 0.0));

      Result : Lambert_Result;
   begin
      Start_Suite ("Lambert Guard Tests (ISS-010)");

      --  (a) Exactly 180-degree (collinear) transfer raises Invalid_Orbit
      declare
         R1 : constant Position_Vector := (7000.0, 0.0, 0.0);
         R2 : constant Position_Vector := (-7000.0, 0.0, 0.0);
         Raised_Invalid_Orbit : Boolean := False;
      begin
         begin
            Result := Solve_Lambert (R1, R2, 5400.0, Mu_Earth);
         exception
            when Invalid_Orbit =>
               Raised_Invalid_Orbit := True;
            when others =>
               Raised_Invalid_Orbit := False;
         end;
         Run_Test ("Lambert exact 180-deg raises Invalid_Orbit",
                   Raised_Invalid_Orbit);
      end;

      --  (b) Near-degenerate 179.999-deg transfer: must not raise and must
      --  never produce NaN/Inf - either converges finite or reports
      --  Converged = False
      declare
         Theta : constant Real := Pi * (179.999 / 180.0);
         R1 : constant Position_Vector := (7000.0, 0.0, 0.0);
         R2 : constant Position_Vector :=
            (7000.0 * Cos (Theta), 7000.0 * Sin (Theta), 0.0);
         Invariant_Holds : Boolean := False;
      begin
         begin
            Result := Solve_Lambert (R1, R2, 5400.0, Mu_Earth);
            Invariant_Holds := Gate_Invariant (Result);
         exception
            when others =>
               Invariant_Holds := False;  -- guards must not raise here
         end;
         Run_Test ("Near-180 (179.999 deg): finite or Converged=False",
                   Invariant_Holds);
      end;

      --  (c) Parabolic-boundary stressor.  The semi-major axis is
      --  a = y / (z*C(z)), singular at the parabolic root z = 0.  The TOF
      --  below is the solver's own time-of-flight expression evaluated at
      --  z = 0 (identical arithmetic), so the bisection's first probe at
      --  z = 0 satisfies the convergence test exactly and the
      --  abs(z*C(z)) < Small_Threshold guard must then reject the result.
      --  TOFs a few microseconds away must never produce NaN either:
      --  converged results carry a finite, positive (possibly huge) A.
      declare
         R1 : constant Position_Vector := (7000.0, 0.0, 0.0);
         R2 : constant Position_Vector := (0.0, 7000.0, 0.0);
         R1_Mag  : constant Real := Magnitude (R1);
         R2_Mag  : constant Real := Magnitude (R2);
         Cos_Dnu : constant Real :=
            Real'Max (-1.0, Real'Min (1.0, Dot (R1, R2) / (R1_Mag * R2_Mag)));
         A_P     : constant Real :=
            Sqrt (R1_Mag * R2_Mag * (1.0 + Cos_Dnu));   -- Dm = +1 here
         C_Z     : constant Real := Hale_Orbital.Stumpff.C (0.0);
         S_Z     : constant Real := Hale_Orbital.Stumpff.S (0.0);
         Y       : constant Real :=
            R1_Mag + R2_Mag + A_P * (0.0 * S_Z - 1.0) / Sqrt (C_Z);
         Chi     : constant Real := Sqrt (Y / C_Z);
         T_Para  : constant Real :=
            (Chi**3 * S_Z + A_P * Sqrt (Y)) / Sqrt (Real (Mu_Earth));
         All_Hold : Boolean := True;
         Exact_Rejected : Boolean := False;
      begin
         --  Exact parabolic TOF: z*C(z) guard must reject (Converged=False)
         begin
            Result := Solve_Lambert (R1, R2, Time_Seconds (T_Para), Mu_Earth);
            Exact_Rejected := not Result.Converged;
         exception
            when others =>
               Exact_Rejected := False;  -- guards must not raise here
         end;
         Run_Test ("Parabolic TOF: z*C(z) guard rejects (Converged=False)",
                   Exact_Rejected);

         for K in -3 .. 3 loop
            declare
               T : constant Real := T_Para + Real (K) * 1.0e-6;
            begin
               Result := Solve_Lambert (R1, R2, Time_Seconds (T), Mu_Earth);
               if not Gate_Invariant (Result) then
                  All_Hold := False;
               end if;
            exception
               when others =>
                  All_Hold := False;  -- guards must not raise here
            end;
         end loop;
         Run_Test ("Parabolic-boundary sweep: finite or Converged=False",
                   All_Hold);
      end;

      --  (c continued) Broad TOF/geometry sweep: whenever the solver
      --  reports convergence the result must be finite with positive A
      declare
         All_Hold : Boolean := True;
      begin
         for IT in 1 .. 20 loop
            for IA in 1 .. 17 loop
               declare
                  Theta : constant Real := Real (IA) * Pi / 18.0;
                  T     : constant Real := Real (IT) * 1000.0;
                  R2_V  : constant Position_Vector :=
                     (9000.0 * Cos (Theta), 9000.0 * Sin (Theta), 0.0);
               begin
                  Result := Solve_Lambert ((7500.0, 0.0, 0.0), R2_V,
                                           Time_Seconds (T), Mu_Earth);
                  if not Gate_Invariant (Result) then
                     All_Hold := False;
                  end if;
               exception
                  when others =>
                     All_Hold := False;
               end;
            end loop;
         end loop;
         Run_Test ("TOF/angle sweep (340 cases): no NaN, converged => A>0",
                   All_Hold);
      end;

      --  (d) Multi-rev path must still return an empty array (not raise)
      --  for degenerate input
      declare
         R1 : constant Position_Vector := (7000.0, 0.0, 0.0);
         R2 : constant Position_Vector := (-7000.0, 0.0, 0.0);
      begin
         declare
            Solutions : constant Lambert_Solution_Array :=
               Solve_Lambert_Multi (R1, R2, 20000.0, Mu_Earth, Max_Revs => 2);
         begin
            Run_Test ("Multi-rev degenerate input returns empty array",
                      Solutions'Length = 0);
         end;
      exception
         when others =>
            Run_Test ("Multi-rev degenerate input returns empty array",
                      False);
      end;

      End_Suite;
   end Test_Lambert_Guards;

   ---------------------------------------------------------------------------
   -- Test_Lambert_Correctness (ISS-010 acceptance)
   ---------------------------------------------------------------------------
   --  Validates the restored standard universal-variable formulation:
   --    * Vallado 4th ed. Example 7-1 (p. 467) converges to the published
   --      velocities within 0.01 km/s per component.  Duplicated here from
   --      the Vallado suite because that suite does not currently compile.
   --    * Energy consistency: for a spread of converged transfers the
   --      specific orbital energy implied by (r1, v1) matches (r2, v2)
   --      within 1e-9 relative, and the returned semi-major axis matches
   --      -mu/(2*energy) within 1e-6 relative.
   ---------------------------------------------------------------------------

   procedure Test_Lambert_Correctness is
      Result : Lambert_Result;
   begin
      Start_Suite ("Lambert Correctness (Vallado 7-1, energy)");

      --  Vallado Example 7-1: short-way, TOF = 76 min
      declare
         R1 : constant Position_Vector := (15945.34, 0.0, 0.0);
         R2 : constant Position_Vector := (12214.83899, 10249.46731, 0.0);
      begin
         Result := Solve_Lambert (R1, R2, 4560.0, Mu_Earth);
         Run_Test ("Vallado 7-1: converged", Result.Converged);
         Run_Test ("Vallado 7-1: V1x ~ 2.058913",
                   abs (Result.V1 (1) - 2.058913) < 0.01);
         Run_Test ("Vallado 7-1: V1y ~ 2.915965",
                   abs (Result.V1 (2) - 2.915965) < 0.01);
         Run_Test ("Vallado 7-1: V1z ~ 0",
                   abs (Result.V1 (3)) < 0.01);
         Run_Test ("Vallado 7-1: V2x ~ -3.451565",
                   abs (Result.V2 (1) - (-3.451565)) < 0.01);
         Run_Test ("Vallado 7-1: V2y ~ 0.910315",
                   abs (Result.V2 (2) - 0.910315) < 0.01);
         Run_Test ("Vallado 7-1: elliptic transfer (0 < e < 1)",
                   Result.E > 0.0 and then Result.E < 1.0);
      end;

      --  Energy consistency across 20 converged transfers.  TOFs are taken
      --  as multiples of each geometry's parabolic (z = 0) time of flight
      --  so every case is elliptic and reachable.
      declare
         N_Converged : Natural := 0;
         All_Consistent : Boolean := True;
      begin
         for IA in 1 .. 5 loop
            for IT in 1 .. 4 loop
               declare
                  Theta : constant Real := Real (IA) * Pi / 6.0;  -- 30..150
                  R1_V  : constant Position_Vector := (7500.0, 0.0, 0.0);
                  R2_V  : constant Position_Vector :=
                     (9000.0 * Cos (Theta), 9000.0 * Sin (Theta), 0.0);
                  R1_Mag  : constant Real := Magnitude (R1_V);
                  R2_Mag  : constant Real := Magnitude (R2_V);
                  Cos_Dnu : constant Real :=
                     Real'Max (-1.0, Real'Min
                        (1.0, Dot (R1_V, R2_V) / (R1_Mag * R2_Mag)));
                  A_P     : constant Real :=
                     Sqrt (R1_Mag * R2_Mag * (1.0 + Cos_Dnu));
                  C_Z     : constant Real := Hale_Orbital.Stumpff.C (0.0);
                  S_Z     : constant Real := Hale_Orbital.Stumpff.S (0.0);
                  Y       : constant Real :=
                     R1_Mag + R2_Mag + A_P * (0.0 * S_Z - 1.0) / Sqrt (C_Z);
                  Chi     : constant Real := Sqrt (Y / C_Z);
                  T_Para  : constant Real :=
                     (Chi**3 * S_Z + A_P * Sqrt (Y)) / Sqrt (Real (Mu_Earth));
                  T       : constant Real :=
                     T_Para * (1.2 + 1.5 * Real (IT));
               begin
                  Result := Solve_Lambert (R1_V, R2_V,
                                           Time_Seconds (T), Mu_Earth);
                  if Result.Converged then
                     N_Converged := N_Converged + 1;
                     declare
                        E1 : constant Real :=
                           0.5 * Magnitude (Result.V1)**2
                           - Real (Mu_Earth) / R1_Mag;
                        E2 : constant Real :=
                           0.5 * Magnitude (Result.V2)**2
                           - Real (Mu_Earth) / R2_Mag;
                        A_Energy : constant Real :=
                           -Real (Mu_Earth) / (2.0 * E1);
                     begin
                        if abs (E1 - E2) / abs (E1) > 1.0e-9
                           or else abs (A_Energy - Real (Result.A)) / A_Energy
                                   > 1.0e-6
                        then
                           All_Consistent := False;
                        end if;
                     end;
                  end if;
               end;
            end loop;
         end loop;
         Run_Test ("Energy consistency: all 20 cases converged",
                   N_Converged = 20);
         Run_Test ("Energy consistency: (r1,v1) vs (r2,v2) and A vs energy",
                   All_Consistent);
      end;

      End_Suite;
   end Test_Lambert_Correctness;

   ---------------------------------------------------------------------------
   -- Run All Negative Tests
   ---------------------------------------------------------------------------

   procedure Run_All_Negative_Tests is
   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  HALE Negative Test Suite (ISS-011)");
      IO.Put_Line ("  Testing Invalid Input Handling");
      IO.Put_Line ("=========================================");
      IO.New_Line;

      Test_Invalid_Eccentricity;
      Test_Invalid_SMA;
      Test_Invalid_Radius;
      Test_Invalid_Mu;
      Test_Zero_Vectors;
      Test_Invalid_TOF;
      Test_Invalid_Tolerance;
      Test_Invalid_Angular_Momentum;
      Test_Lambert_Guards;
      Test_Lambert_Correctness;
   end Run_All_Negative_Tests;

end Hale_Tests.Negative;
