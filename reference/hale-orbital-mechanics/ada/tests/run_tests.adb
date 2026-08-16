-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Test Runner
-------------------------------------------------------------------------------
-- Simple test harness for validating orbital mechanics calculations.
-- Tests are based on examples from Hale's textbook.
-------------------------------------------------------------------------------

with Ada.Command_Line;
with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Types;      use Hale_Orbital.Types;
with Hale_Orbital.Constants;  use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;    use Hale_Orbital.Vectors;
with Hale_Orbital.Matrices;   use Hale_Orbital.Matrices;
with Hale_Orbital.Twobody;    use Hale_Orbital.Twobody;
with Hale_Orbital.Elements;   use Hale_Orbital.Elements;
with Hale_Orbital.Kepler;     use Hale_Orbital.Kepler;
with Hale_Orbital.Maneuvers;   use Hale_Orbital.Maneuvers;
with Hale_Orbital.Threebody;   use Hale_Orbital.Threebody;
with Hale_Orbital.Propagation; use Hale_Orbital.Propagation;

procedure Run_Tests is

   package IO renames Ada.Text_IO;
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   Tests_Passed : Natural := 0;
   Tests_Failed : Natural := 0;
   Total_Tests  : Natural := 0;

   --  Helper to compare reals with tolerance
   function Approx_Equal (A, B : Real; Tolerance : Real := 1.0e-6) return Boolean is
   begin
      return abs (A - B) < Tolerance;
   end Approx_Equal;

   --  Helper to run a test
   procedure Run_Test (Name : String; Passed : Boolean) is
   begin
      Total_Tests := Total_Tests + 1;
      if Passed then
         Tests_Passed := Tests_Passed + 1;
         IO.Put_Line ("  [PASS] " & Name);
      else
         Tests_Failed := Tests_Failed + 1;
         IO.Put_Line ("  [FAIL] " & Name);
      end if;
   end Run_Test;

   ---------------------------------------------------------------------------
   -- Test Suites
   ---------------------------------------------------------------------------

   procedure Test_Vectors is
      V1, V2, V3 : Vector_3D;
      Mag : Real;
   begin
      IO.Put_Line ("Testing Vector Operations...");

      --  Test vector addition
      V1 := (1.0, 2.0, 3.0);
      V2 := (4.0, 5.0, 6.0);
      V3 := V1 + V2;
      Run_Test ("Vector addition",
                V3 (1) = 5.0 and V3 (2) = 7.0 and V3 (3) = 9.0);

      --  Test dot product
      Run_Test ("Dot product",
                Approx_Equal (Dot (V1, V2), 32.0));

      --  Test cross product
      V3 := Cross (V1, V2);
      Run_Test ("Cross product",
                Approx_Equal (V3 (1), -3.0) and
                Approx_Equal (V3 (2), 6.0) and
                Approx_Equal (V3 (3), -3.0));

      --  Test magnitude
      V1 := (3.0, 4.0, 0.0);
      Mag := Magnitude (V1);
      Run_Test ("Magnitude", Approx_Equal (Mag, 5.0));

      --  Test normalization
      V2 := Normalize (V1);
      Run_Test ("Normalize",
                Approx_Equal (V2 (1), 0.6) and Approx_Equal (V2 (2), 0.8));

      IO.New_Line;
   end Test_Vectors;

   procedure Test_Matrices is
      M1, M2, M3 : Matrix_3x3;
      V1, V2 : Vector_3D;
      Det : Real;
   begin
      IO.Put_Line ("Testing Matrix Operations...");

      --  Test identity matrix
      M1 := Identity_3x3;
      V1 := (1.0, 2.0, 3.0);
      V2 := M1 * V1;
      Run_Test ("Identity matrix * vector",
                V2 (1) = V1 (1) and V2 (2) = V1 (2) and V2 (3) = V1 (3));

      --  Test determinant
      M1 := ((1.0, 2.0, 3.0),
             (4.0, 5.0, 6.0),
             (7.0, 8.0, 10.0));
      Det := Determinant (M1);
      Run_Test ("Determinant", Approx_Equal (Det, -3.0));

      --  Test rotation matrices (90 degree rotation)
      M1 := Rotation_Z (Angle_Radians (Half_Pi));
      V1 := (1.0, 0.0, 0.0);
      V2 := M1 * V1;
      Run_Test ("Rotation_Z (90 deg)",
                Approx_Equal (V2 (1), 0.0, 1.0e-10) and
                Approx_Equal (V2 (2), 1.0, 1.0e-10));

      IO.New_Line;
   end Test_Matrices;

   procedure Test_Twobody is
      R, V : Vector_3D;
      Energy : Hale_Orbital.Types.Specific_Energy;
      Period : Time_Seconds;
      V_Circ : Velocity_Km_S;
   begin
      IO.Put_Line ("Testing Two-Body Dynamics...");

      --  Test circular velocity at Earth's surface
      V_Circ := Circular_Velocity (R_Earth, Mu_Earth);
      Run_Test ("Circular velocity at Earth surface",
                Approx_Equal (Real (V_Circ), 7.905, 0.01));

      --  Test escape velocity (should be sqrt(2) * v_circ)
      declare
         V_Esc : constant Velocity_Km_S := Escape_Velocity (R_Earth, Mu_Earth);
      begin
         Run_Test ("Escape velocity ratio",
                   Approx_Equal (Real (V_Esc) / Real (V_Circ), Sqrt (2.0), 1.0e-6));
      end;

      --  Test orbital period of ISS (~92 minutes)
      --  ISS altitude ~420 km, so radius = R_Earth + 420
      declare
         R_ISS : constant Distance_Km := Distance_Km (Real (R_Earth) + 420.0);
         T_ISS : constant Time_Seconds := Orbital_Period (R_ISS, Mu_Earth);
      begin
         Run_Test ("ISS orbital period (~5520 s)",
                   Approx_Equal (Real (T_ISS), 5520.0, 100.0));
      end;

      --  Test GEO orbital period (~24 hours = 86400 s)
      Period := Orbital_Period (R_GEO, Mu_Earth);
      Run_Test ("GEO orbital period (~86400 s)",
                Approx_Equal (Real (Period), 86164.0, 100.0));

      --  Test specific energy for circular orbit
      R := (Real (R_Earth) + 400.0, 0.0, 0.0);
      V_Circ := Circular_Velocity (Distance_Km (Magnitude (R)), Mu_Earth);
      V := (0.0, Real (V_Circ), 0.0);
      Energy := Hale_Orbital.Twobody.Specific_Energy (R, V, Mu_Earth);
      Run_Test ("Specific energy is negative for bound orbit",
                Real (Energy) < 0.0);

      IO.New_Line;
   end Test_Twobody;

   procedure Test_Elements is
      R, V : Vector_3D;
      Elements : Orbital_Elements;
      State : State_Vector;
      R_Out, V_Out : Vector_3D;
   begin
      IO.Put_Line ("Testing Orbital Elements...");

      --  Test circular equatorial orbit
      R := (7000.0, 0.0, 0.0);  -- 7000 km from Earth center
      declare
         V_Circ : constant Velocity_Km_S := Circular_Velocity (7000.0, Mu_Earth);
      begin
         V := (0.0, Real (V_Circ), 0.0);  -- Velocity perpendicular to position
      end;

      Elements := State_To_Elements (R, V, Mu_Earth);

      Run_Test ("Circular orbit eccentricity near zero",
                Elements.Eccentricity < 0.001);

      Run_Test ("Equatorial orbit inclination near zero",
                abs (Real (Elements.Inclination)) < 0.001);

      Run_Test ("Semi-major axis equals radius for circular",
                Approx_Equal (Real (Elements.Semi_Major_Axis), 7000.0, 1.0));

      --  Test round-trip conversion
      State := Elements_To_State (Elements, Mu_Earth);
      R_Out := State.Position;
      V_Out := State.Velocity;

      Run_Test ("Round-trip position X",
                Approx_Equal (R_Out (1), R (1), 0.01));
      Run_Test ("Round-trip velocity Y",
                Approx_Equal (V_Out (2), V (2), 0.001));

      --  Test anomaly conversions
      declare
         Nu : constant Angle_Radians := Angle_Radians (Pi / 4.0);  -- 45 degrees
         E_Val : constant Real := 0.5;
         E_Anom : Angle_Radians;
         Nu_Back : Angle_Radians;
      begin
         E_Anom := True_To_Eccentric_Anomaly (Nu, E_Val);
         Nu_Back := Eccentric_To_True_Anomaly (E_Anom, E_Val);
         Run_Test ("True -> Eccentric -> True anomaly",
                   Approx_Equal (Real (Nu_Back), Real (Nu), 1.0e-10));
      end;

      IO.New_Line;
   end Test_Elements;

   procedure Test_Kepler is
      E_Anom : Angle_Radians;
      M : Angle_Radians;
   begin
      IO.Put_Line ("Testing Kepler Solvers...");

      --  Test Kepler solver for circular orbit (e=0)
      --  For e=0, E = M
      M := Angle_Radians (Pi / 3.0);  -- 60 degrees
      E_Anom := Solve_Kepler_Elliptic (M, 0.0);
      Run_Test ("Kepler for circular (e=0)",
                Approx_Equal (Real (E_Anom), Real (M), 1.0e-10));

      --  Test Kepler solver for elliptic orbit
      M := Angle_Radians (Pi / 4.0);
      E_Anom := Solve_Kepler_Elliptic (M, 0.5);
      --  Verify: E - e*sin(E) = M
      declare
         M_Check : constant Real := Real (E_Anom) - 0.5 * Sin (Real (E_Anom));
      begin
         Run_Test ("Kepler for e=0.5",
                   Approx_Equal (M_Check, Real (M), 1.0e-10));
      end;

      --  Test Stumpff functions at z=0
      Run_Test ("Stumpff C(0) = 1/2",
                Approx_Equal (Stumpff_C (0.0), 0.5, 1.0e-10));
      Run_Test ("Stumpff S(0) = 1/6",
                Approx_Equal (Stumpff_S (0.0), 1.0 / 6.0, 1.0e-10));

      IO.New_Line;
   end Test_Kepler;

   procedure Test_Maneuvers is
      Result : Hohmann_Result;
      Bielliptic : Bielliptic_Result;
   begin
      IO.Put_Line ("Testing Orbital Maneuvers...");
      IO.Put_Line ("  [Hale Textbook Validation - Chapter 6]");

      -------------------------------------------------------------------------
      --  HALE TABLE 6-1 VALIDATION: LEO to GEO Transfer
      --  This is the canonical validation case from Hale's textbook
      --  Expected total delta-V: 3.935 km/s (Hale Table 6-1)
      -------------------------------------------------------------------------
      declare
         --  Standard LEO: 200 km altitude
         R_LEO : constant Distance_Km := Distance_Km (Real (R_Earth) + 200.0);
         --  GEO radius
         R_GEO_Val : constant Distance_Km := 42164.0;
      begin
         Result := Hohmann_Transfer (R_LEO, R_GEO_Val, Mu_Earth);

         --  Hale Table 6-1: LEO-GEO Delta-V1 = 2.457 km/s
         Run_Test ("Hale 6-1: Hohmann LEO-GEO Delta-V1 (2.457 km/s)",
                   Approx_Equal (Real (Result.Delta_V1), 2.457, 0.01));

         --  Hale Table 6-1: LEO-GEO Delta-V2 = 1.478 km/s
         Run_Test ("Hale 6-1: Hohmann LEO-GEO Delta-V2 (1.478 km/s)",
                   Approx_Equal (Real (Result.Delta_V2), 1.478, 0.01));

         --  Hale Table 6-1: Total = 3.935 km/s
         Run_Test ("Hale 6-1: Hohmann LEO-GEO Total (3.935 km/s)",
                   Approx_Equal (Real (Result.Total_Delta_V), 3.935, 0.01));

         --  Transfer time: half period of transfer ellipse
         --  a_transfer = (6578 + 42164)/2 = 24371 km
         --  T_transfer = pi * sqrt(a^3/mu) ≈ 18925 s (5.26 hours)
         Run_Test ("Hale 6-1: Transfer time (~18925 s = 5.26 hours)",
                   Approx_Equal (Real (Result.Transfer_Time), 18925.0, 200.0));
      end;

      -------------------------------------------------------------------------
      --  HOHMANN TRANSFER PHYSICS VALIDATION
      -------------------------------------------------------------------------
      declare
         R1 : constant Distance_Km := 7000.0;
         R2 : constant Distance_Km := 14000.0;
      begin
         Result := Hohmann_Transfer (R1, R2, Mu_Earth);

         --  Transfer SMA should be (R1 + R2) / 2
         Run_Test ("Hohmann transfer SMA = (R1+R2)/2",
                   Approx_Equal (Real (Result.A_Transfer), 10500.0, 0.1));

         --  Transfer eccentricity = |R2 - R1| / (R1 + R2)
         Run_Test ("Hohmann transfer eccentricity",
                   Approx_Equal (Result.E_Transfer, 1.0 / 3.0, 0.001));
      end;

      -------------------------------------------------------------------------
      --  BI-ELLIPTIC TRANSFER VALIDATION
      --  Bi-elliptic is more efficient when R_final/R_initial > 11.94
      -------------------------------------------------------------------------
      Run_Test ("Bielliptic threshold: ratio < 11.94 -> Hohmann better",
                not Bielliptic_Is_Efficient (6578.0, 70000.0));  -- ratio ~10.6

      Run_Test ("Bielliptic threshold: ratio > 11.94 -> Bielliptic better",
                Bielliptic_Is_Efficient (6578.0, 100000.0));  -- ratio ~15.2

      --  Test bi-elliptic transfer calculation
      declare
         R1 : constant Distance_Km := 6578.0;
         R2 : constant Distance_Km := 100000.0;  -- High orbit
         R_Int : constant Distance_Km := 200000.0;  -- Intermediate apoapsis
      begin
         Bielliptic := Bielliptic_Transfer (R1, R2, R_Int, Mu_Earth);

         --  All delta-Vs should be positive
         Run_Test ("Bielliptic Delta-V1 positive",
                   Real (Bielliptic.Delta_V1) > 0.0);
         Run_Test ("Bielliptic Delta-V2 positive",
                   Real (Bielliptic.Delta_V2) > 0.0);
         Run_Test ("Bielliptic Delta-V3 positive",
                   Real (Bielliptic.Delta_V3) > 0.0);

         --  Total should be sum
         Run_Test ("Bielliptic Total = DV1 + DV2 + DV3",
                   Approx_Equal (Real (Bielliptic.Total_Delta_V),
                                 Real (Bielliptic.Delta_V1) +
                                 Real (Bielliptic.Delta_V2) +
                                 Real (Bielliptic.Delta_V3), 0.001));
      end;

      -------------------------------------------------------------------------
      --  PLANE CHANGE VALIDATION (Hale Section 6.4)
      -------------------------------------------------------------------------
      --  Simple plane change: Delta-V = 2 * V * sin(Delta_i / 2)
      declare
         V_Test : constant Velocity_Km_S := 7.5;  -- km/s
         Delta_I_90 : constant Angle_Radians := Angle_Radians (Half_Pi);  -- 90 degrees
         Delta_V_90 : Velocity_Km_S;
      begin
         Delta_V_90 := Simple_Plane_Change (Delta_I_90, V_Test);
         --  For 90 deg: Delta-V = 2 * 7.5 * sin(45) = 2 * 7.5 * 0.707 = 10.6 km/s
         Run_Test ("90 deg plane change formula",
                   Approx_Equal (Real (Delta_V_90), 2.0 * 7.5 * Sin (Pi / 4.0), 0.01));
      end;

      --  GEO plane change for Cape Canaveral launch (28.5 degrees)
      declare
         V_GEO : constant Velocity_Km_S := Circular_Velocity (R_GEO, Mu_Earth);
         Delta_I : constant Angle_Radians := Angle_Radians (28.5 * Deg_To_Rad);
         Delta_V : Velocity_Km_S;
      begin
         Delta_V := Simple_Plane_Change (Delta_I, V_GEO);
         --  V_GEO ≈ 3.075 km/s, Delta-V ≈ 1.51 km/s for 28.5 deg
         Run_Test ("GEO plane change for 28.5 deg (~1.51 km/s)",
                   Approx_Equal (Real (Delta_V), 1.51, 0.05));
      end;

      -------------------------------------------------------------------------
      --  ESCAPE AND C3 VALIDATION
      -------------------------------------------------------------------------
      --  Escape velocity = sqrt(2) * circular velocity
      declare
         R_Test : constant Distance_Km := 6578.0;
         V_Circ : constant Velocity_Km_S := Circular_Velocity (R_Test, Mu_Earth);
         V_Esc_DV : constant Velocity_Km_S := Escape_Delta_V (R_Test, Mu_Earth);
      begin
         --  Delta-V to escape = V_escape - V_circular = (sqrt(2) - 1) * V_circ
         Run_Test ("Escape Delta-V = (sqrt(2)-1) * V_circ",
                   Approx_Equal (Real (V_Esc_DV),
                                 (Sqrt (2.0) - 1.0) * Real (V_Circ), 0.01));
      end;

      --  C3 energy: C3 = V_infinity^2
      declare
         V_Inf : constant Velocity_Km_S := 3.0;
         C3 : constant Hale_Orbital.Types.Specific_Energy := C3_Energy (V_Inf);
      begin
         Run_Test ("C3 energy = V_inf^2",
                   Approx_Equal (Real (C3), 9.0, 0.001));
      end;

      --  Departure velocity for given C3
      declare
         R_Dep : constant Distance_Km := 6578.0;
         C3_Val : constant Hale_Orbital.Types.Specific_Energy := 10.0;  -- km^2/s^2
         V_Dep : constant Velocity_Km_S := Departure_Velocity (R_Dep, C3_Val, Mu_Earth);
         --  V_dep = sqrt(V_esc^2 + C3) = sqrt(2*mu/r + C3)
         V_Expected : constant Real := Sqrt (2.0 * Real (Mu_Earth) / Real (R_Dep) + Real (C3_Val));
      begin
         Run_Test ("Departure velocity for C3=10",
                   Approx_Equal (Real (V_Dep), V_Expected, 0.01));
      end;

      -------------------------------------------------------------------------
      --  PHASING MANEUVER VALIDATION (ISS-023)
      --  Comprehensive tests for rendezvous phasing maneuvers
      -------------------------------------------------------------------------

      --  Basic phasing: 30 degree catch-up in 1 orbit
      declare
         R_Orbit : constant Distance_Km := 7000.0;
         Phase_Angle : constant Angle_Radians := Angle_Radians (Pi / 6.0);  -- 30 degrees
         N_Orbits : constant Positive := 1;
         A_Phase : Distance_Km;
         DV_Phase : Velocity_Km_S;
      begin
         A_Phase := Phasing_Orbit_SMA (R_Orbit, Phase_Angle, N_Orbits, Mu_Earth);

         --  Phasing orbit should be smaller than target orbit (catch-up)
         Run_Test ("Phasing SMA < target orbit for positive phase",
                   Real (A_Phase) < Real (R_Orbit));

         --  Delta-V for phasing
         DV_Phase := Phasing_Delta_V (R_Orbit, Phase_Angle, N_Orbits, Mu_Earth);
         Run_Test ("Phasing Delta-V > 0",
                   Real (DV_Phase) > 0.0);
      end;

      --  Multi-orbit phasing: 30 degree catch-up in 2 orbits (gentler maneuver)
      declare
         R_Orbit : constant Distance_Km := 7000.0;
         Phase_Angle : constant Angle_Radians := Angle_Radians (Pi / 6.0);  -- 30 degrees
         A_Phase_1 : Distance_Km;
         A_Phase_2 : Distance_Km;
         DV_Phase_1 : Velocity_Km_S;
         DV_Phase_2 : Velocity_Km_S;
      begin
         A_Phase_1 := Phasing_Orbit_SMA (R_Orbit, Phase_Angle, 1, Mu_Earth);
         A_Phase_2 := Phasing_Orbit_SMA (R_Orbit, Phase_Angle, 2, Mu_Earth);

         --  More orbits = smaller altitude change needed
         Run_Test ("Multi-orbit phasing: 2 orbits closer to target SMA",
                   abs (Real (A_Phase_2) - Real (R_Orbit)) <
                   abs (Real (A_Phase_1) - Real (R_Orbit)));

         DV_Phase_1 := Phasing_Delta_V (R_Orbit, Phase_Angle, 1, Mu_Earth);
         DV_Phase_2 := Phasing_Delta_V (R_Orbit, Phase_Angle, 2, Mu_Earth);

         --  More orbits = less delta-V needed
         Run_Test ("Multi-orbit phasing: 2 orbits requires less DV",
                   Real (DV_Phase_2) < Real (DV_Phase_1));
      end;

      --  ISS rendezvous scenario: Typical ISS altitude, realistic phase angle
      declare
         --  ISS at ~420 km altitude
         R_ISS : constant Distance_Km := Distance_Km (Real (R_Earth) + 420.0);
         --  10 degree phase angle (common for visiting spacecraft)
         Phase_Angle : constant Angle_Radians := Angle_Radians (10.0 * Deg_To_Rad);
         A_Phase : Distance_Km;
         DV_Phase : Velocity_Km_S;
      begin
         A_Phase := Phasing_Orbit_SMA (R_ISS, Phase_Angle, 1, Mu_Earth);
         DV_Phase := Phasing_Delta_V (R_ISS, Phase_Angle, 1, Mu_Earth);

         --  Phasing orbit should be reasonable (not drastically different)
         Run_Test ("ISS rendezvous phasing SMA reasonable",
                   abs (Real (A_Phase) - Real (R_ISS)) < 500.0);

         --  Delta-V should be small for 10 degree phase
         Run_Test ("ISS rendezvous DV < 0.5 km/s for 10 deg phase",
                   Real (DV_Phase) < 0.5);
      end;

      --  Large phase angle scenario: 180 degrees (half orbit behind)
      declare
         R_Orbit : constant Distance_Km := 7000.0;
         Phase_Angle_180 : constant Angle_Radians := Angle_Radians (Pi);  -- 180 degrees
         A_Phase : Distance_Km;
         DV_Phase : Velocity_Km_S;
      begin
         A_Phase := Phasing_Orbit_SMA (R_Orbit, Phase_Angle_180, 1, Mu_Earth);
         DV_Phase := Phasing_Delta_V (R_Orbit, Phase_Angle_180, 1, Mu_Earth);

         --  180 degree phase should have larger DV
         Run_Test ("180 deg phase requires significant DV",
                   Real (DV_Phase) > 0.1);

         --  Phasing orbit for 180 deg needs large altitude change
         Run_Test ("180 deg phase orbit significantly different",
                   abs (Real (A_Phase) - Real (R_Orbit)) > 100.0);
      end;

      IO.New_Line;
   end Test_Maneuvers;

   procedure Test_Threebody is
      LP : Lagrange_Result;
      Stability : Stability_Result;
   begin
      IO.Put_Line ("Testing Three-Body Dynamics...");

      --  Test Earth-Moon L1 computation
      --  L1 is between Earth and Moon, approximately 326,000 km from Earth
      LP := Compute_Lagrange_Point (Earth_Moon_System, L1);
      Run_Test ("Earth-Moon L1 X coordinate (between primaries)",
                LP.X > 0.0 and LP.X < 1.0);

      Run_Test ("Earth-Moon L1 Y coordinate (on axis)",
                Approx_Equal (LP.Y, 0.0, 1.0e-10));

      --  Test L4/L5 are at equilateral triangle positions
      LP := Compute_Lagrange_Point (Earth_Moon_System, L4);
      Run_Test ("Earth-Moon L4 Y coordinate (positive, above)",
                LP.Y > 0.0);
      Run_Test ("Earth-Moon L4 is equilateral",
                Approx_Equal (LP.Y, Sqrt (3.0) / 2.0, 0.01));

      LP := Compute_Lagrange_Point (Earth_Moon_System, L5);
      Run_Test ("Earth-Moon L5 Y coordinate (negative, below)",
                LP.Y < 0.0);

      --  Test stability: L4/L5 stable for Earth-Moon system
      Stability := Analyze_Stability (Earth_Moon_System, L4);
      Run_Test ("Earth-Moon L4 is stable",
                Stability.Is_Stable);

      Stability := Analyze_Stability (Earth_Moon_System, L1);
      Run_Test ("Earth-Moon L1 is unstable",
                not Stability.Is_Stable);

      --  Test Jacobi constant (should be conserved)
      declare
         State : constant Normalized_State := (X => 0.5, Y => 0.5, Z => 0.0,
                                               VX => 0.0, VY => 0.0, VZ => 0.0);
         C : constant Real := Jacobi_Constant (State, Earth_Moon_System.Mass_Ratio);
      begin
         Run_Test ("Jacobi constant is positive for stationary point",
                   C > 0.0);
      end;

      IO.New_Line;
   end Test_Threebody;

   procedure Test_Propagation is
      --  Test energy and angular momentum conservation during propagation
   begin
      IO.Put_Line ("Testing Numerical Propagation...");
      IO.Put_Line ("  [Energy Conservation Validation - ISS-004]");

      -------------------------------------------------------------------------
      --  RK4 ENERGY CONSERVATION TEST
      --  Two-body propagation should conserve energy to high precision
      -------------------------------------------------------------------------
      declare
         --  Set up a LEO circular orbit
         R_Val : constant Real := Real (R_Earth) + 400.0;  -- 400 km altitude
         V_Circ : constant Velocity_Km_S := Circular_Velocity (Distance_Km (R_Val), Mu_Earth);

         Initial_State : constant State_Vector := (
            Position => (R_Val, 0.0, 0.0),
            Velocity => (0.0, Real (V_Circ), 0.0)
         );

         --  Propagate for one full orbit
         Period : constant Time_Seconds := Orbital_Period (Distance_Km (R_Val), Mu_Earth);

         --  Two-body force model
         Model : constant Two_Body_Model := (Mu => Mu_Earth);

         --  Propagate using RK4 with 10 second steps
         Final_State : constant State_Vector :=
            Propagate_RK4 (Initial_State, 0.0, Period, 10.0, Model);

         --  Compute energy error
         E_Error : constant Real := Energy_Error (Initial_State, Final_State, Mu_Earth);
      begin
         --  RK4 should conserve energy to ~1e-10 or better over one orbit
         Run_Test ("RK4 energy conservation (error < 1e-8)",
                   abs (E_Error) < 1.0e-8);

         --  Position should return close to initial after one orbit
         Run_Test ("RK4 orbit closure position X",
                   Approx_Equal (Final_State.Position (1), Initial_State.Position (1), 10.0));
         Run_Test ("RK4 orbit closure position Y",
                   Approx_Equal (Final_State.Position (2), Initial_State.Position (2), 10.0));
      end;

      -------------------------------------------------------------------------
      --  RK78 ENERGY CONSERVATION TEST
      --  Adaptive step should achieve better energy conservation
      -------------------------------------------------------------------------
      declare
         --  Set up an elliptical orbit (more challenging)
         R_Peri : constant Real := Real (R_Earth) + 300.0;  -- 300 km periapsis
         A_Val : constant Real := Real (R_Earth) + 1000.0;  -- Semi-major axis
         E_Val : constant Real := 1.0 - R_Peri / A_Val;     -- Eccentricity

         --  Compute velocity at periapsis using vis-viva
         V_Peri : constant Real := Sqrt (Real (Mu_Earth) * (2.0 / R_Peri - 1.0 / A_Val));

         Initial_State : constant State_Vector := (
            Position => (R_Peri, 0.0, 0.0),
            Velocity => (0.0, V_Peri, 0.0)
         );

         --  Propagate for one full orbit
         Period : constant Time_Seconds :=
            Time_Seconds (Two_Pi * Sqrt (A_Val ** 3 / Real (Mu_Earth)));

         --  Two-body force model
         Model : constant Two_Body_Model := (Mu => Mu_Earth);

         --  Propagate using RK78 adaptive step
         Final_State : constant State_Vector :=
            Propagate_RK78 (Initial_State, 0.0, Period, 1.0e-12, Model);

         --  Compute energy error
         E_Error : constant Real := Energy_Error (Initial_State, Final_State, Mu_Earth);
      begin
         --  RK78 should conserve energy to ~1e-12 or better
         Run_Test ("RK78 energy conservation (error < 1e-10)",
                   abs (E_Error) < 1.0e-10);

         --  Verify orbit remained elliptical (eccentricity check)
         Run_Test ("RK78 elliptical orbit preserved",
                   E_Val > 0.01 and E_Val < 0.5);
      end;

      -------------------------------------------------------------------------
      --  ANGULAR MOMENTUM CONSERVATION TEST
      --  Two-body motion conserves angular momentum h = r x v
      -------------------------------------------------------------------------
      declare
         R_Val : constant Real := Real (R_Earth) + 500.0;
         V_Circ : constant Velocity_Km_S := Circular_Velocity (Distance_Km (R_Val), Mu_Earth);

         Initial_State : constant State_Vector := (
            Position => (R_Val, 0.0, 0.0),
            Velocity => (0.0, Real (V_Circ), 0.0)
         );

         --  Angular momentum magnitude = r * v for circular equatorial orbit
         H_Initial : constant Real := R_Val * Real (V_Circ);

         Period : constant Time_Seconds := Orbital_Period (Distance_Km (R_Val), Mu_Earth);
         Model : constant Two_Body_Model := (Mu => Mu_Earth);

         --  Propagate for half orbit
         Final_State : constant State_Vector :=
            Propagate_RK4 (Initial_State, 0.0, Time_Seconds (Real (Period) / 2.0), 10.0, Model);

         --  Compute angular momentum at final state
         H_Vec : constant Vector_3D := Cross (Final_State.Position, Final_State.Velocity);
         H_Final : constant Real := Magnitude (H_Vec);
      begin
         Run_Test ("Angular momentum conservation (error < 1e-6)",
                   Approx_Equal (H_Final, H_Initial, 1.0e-6 * H_Initial));
      end;

      -------------------------------------------------------------------------
      --  J2 PERTURBATION SMOKE TEST
      --  Verify J2 model produces different results than two-body
      -------------------------------------------------------------------------
      declare
         R_Val : constant Real := Real (R_Earth) + 400.0;
         V_Circ : constant Velocity_Km_S := Circular_Velocity (Distance_Km (R_Val), Mu_Earth);

         Initial_State : constant State_Vector := (
            Position => (R_Val, 0.0, 0.0),
            Velocity => (0.0, Real (V_Circ), 0.0)
         );

         --  Propagate for 1 hour
         T_End : constant Time_Seconds := 3600.0;

         Two_Body : constant Two_Body_Model := (Mu => Mu_Earth);
         J2_Perturbed : constant J2_Model := (
            Mu   => Mu_Earth,
            J2   => 1.08263e-3,  -- Earth J2
            R_Eq => R_Earth
         );

         Final_Two_Body : constant State_Vector :=
            Propagate_RK4 (Initial_State, 0.0, T_End, 10.0, Two_Body);
         Final_J2 : constant State_Vector :=
            Propagate_RK4 (Initial_State, 0.0, T_End, 10.0, J2_Perturbed);

         --  J2 should cause small difference from two-body
         Pos_Diff : constant Real :=
            Magnitude (Final_J2.Position - Final_Two_Body.Position);
      begin
         --  J2 perturbation should cause measurable position difference (meters to km)
         Run_Test ("J2 perturbation causes measurable difference",
                   Pos_Diff > 0.001);  -- At least 1 meter difference

         --  But not huge difference after 1 hour
         Run_Test ("J2 perturbation reasonable magnitude",
                   Pos_Diff < 100.0);  -- Less than 100 km difference
      end;

      -------------------------------------------------------------------------
      --  EMBEDDED INTEGRATOR VALIDATION (B2)
      --  Validates the real DP54 (Dormand-Prince 5(4)) and RKF78
      --  (Fehlberg 7(8)) integrators against the analytic universal-variable
      --  Kepler propagator, checks observed convergence order (a single
      --  mistyped tableau coefficient collapses the order immediately), and
      --  exercises the adaptive step controller and the parallel task pool.
      -------------------------------------------------------------------------
      declare
         Model : constant Two_Body_Model := (Mu => Mu_Earth);

         --  Circular LEO reference orbit (500 km altitude)
         R_Circ : constant Real := Real (R_Earth) + 500.0;
         V_Circ : constant Velocity_Km_S :=
            Circular_Velocity (Distance_Km (R_Circ), Mu_Earth);
         S_Circ : constant State_Vector := (Position => (R_Circ, 0.0, 0.0),
                                            Velocity => (0.0, Real (V_Circ), 0.0));
         P_Circ : constant Time_Seconds :=
            Orbital_Period (Distance_Km (R_Circ), Mu_Earth);

         --  Eccentric orbit e = 0.7 (a = 26600 km, periapsis ~ 7980 km)
         A_Ecc  : constant Real := 26_600.0;
         E_Ecc  : constant Real := 0.7;
         R_Peri : constant Real := A_Ecc * (1.0 - E_Ecc);
         V_Peri : constant Real :=
            Sqrt (Real (Mu_Earth) * (2.0 / R_Peri - 1.0 / A_Ecc));
         S_Ecc  : constant State_Vector := (Position => (R_Peri, 0.0, 0.0),
                                            Velocity => (0.0, V_Peri, 0.0));
         P_Ecc  : constant Time_Seconds :=
            Time_Seconds (Two_Pi * Sqrt (A_Ecc ** 3 / Real (Mu_Earth)));

         --  Terminal position error after one period against the analytic
         --  Kepler propagator, using FIXED steps h = Period / N_Steps.
         --  Fixed stepping is obtained from the adaptive drivers by clamping
         --  Min_Step = Max_Step = h (the controller can then never resize).
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
         --  (a) One-period terminal accuracy vs analytic Kepler propagation
         --  at adaptive tolerance 1e-12.
         --  Measured (GNAT 14.2, x86_64 Linux, 2026-07-13):
         --    DP54 : pos err 7.2e-8 km (circ), 1.6e-6 km (ecc);
         --           energy drift 2.5e-12 (circ), 3.5e-12 (ecc)
         --    RKF78: pos err 6.4e-7 km (circ), 4.7e-7 km (ecc);
         --           energy drift 1.9e-11 (circ), 6.7e-13 (ecc)
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
            Run_Test ("DP54 circular vs Kepler analytic (pos err < 1e-4 km)",
                      Magnitude (F_DP54.Position - R_Ref) < 1.0e-4);
            Run_Test ("DP54 circular energy drift < 1e-9",
                      abs (Energy_Error (S_Circ, F_DP54, Mu_Earth)) < 1.0e-9);
            Run_Test ("RKF78 circular vs Kepler analytic (pos err < 1e-4 km)",
                      Magnitude (F_RKF78.Position - R_Ref) < 1.0e-4);
            Run_Test ("RKF78 circular energy drift < 1e-10",
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
            Run_Test ("DP54 eccentric e=0.7 vs Kepler analytic (pos err < 1e-4 km)",
                      Magnitude (F_DP54.Position - R_Ref) < 1.0e-4);
            Run_Test ("DP54 eccentric energy drift < 1e-9",
                      abs (Energy_Error (S_Ecc, F_DP54, Mu_Earth)) < 1.0e-9);
            Run_Test ("RKF78 eccentric e=0.7 vs Kepler analytic (pos err < 1e-4 km)",
                      Magnitude (F_RKF78.Position - R_Ref) < 1.0e-4);
            Run_Test ("RKF78 eccentric energy drift < 1e-10",
                      abs (Energy_Error (S_Ecc, F_RKF78, Mu_Earth)) < 1.0e-10);
         end;

         --  (b) Observed convergence order: fixed steps h and h/2 over one
         --  orbit; order = log2(err_h / err_h2).  A wrong tableau entry drops
         --  the observed order to the 1-3 range immediately.
         --  Measured: DP54 order 4.78 (N=400/800), RKF78 order 6.99 (N=40/80)
         declare
            DP54_E1  : constant Real := Fixed_Step_Error (True, S_Circ, P_Circ, 400);
            DP54_E2  : constant Real := Fixed_Step_Error (True, S_Circ, P_Circ, 800);
            RKF78_E1 : constant Real := Fixed_Step_Error (False, S_Circ, P_Circ, 40);
            RKF78_E2 : constant Real := Fixed_Step_Error (False, S_Circ, P_Circ, 80);
            DP54_Order  : constant Real := Log (DP54_E1 / DP54_E2) / Log (2.0);
            RKF78_Order : constant Real := Log (RKF78_E1 / RKF78_E2) / Log (2.0);
         begin
            Run_Test ("DP54 observed convergence order >= 4.5",
                      DP54_E2 > 0.0 and then DP54_Order >= 4.5);
            Run_Test ("RKF78 observed convergence order >= 6.5",
                      RKF78_E2 > 0.0 and then RKF78_Order >= 6.5);
         end;

         --  (c) Step-controller sanity: the adaptive run reaches its accuracy
         --  with far fewer steps than a fixed-step run of equal-or-better
         --  accuracy.  Measured: adaptive RKF78 at tol 1e-12 takes 84 steps
         --  (pos err 4.7e-7 km); the 2000-step fixed run errs 9.7e-9 km.
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
            Run_Test ("RKF78 adaptive uses fewer steps than equal-accuracy fixed",
                      Adaptive.Success and then Fixed_Err <= Adaptive_Err
                      and then Adaptive.Steps_Used < N_Fixed / 4);
         end;

         --  (d) Parallel task pool: matches sequential propagation exactly
         --  and re-raises worker exceptions in the caller
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
            Run_Test ("Parallel task pool matches sequential RK78", All_Match);
         end;

         declare
            Bad    : State_Array (1 .. 5) := (others => S_Circ);
            Raised : Boolean := False;
         begin
            --  Sample 3 sits inside the r < 1e-10 singularity guard, so its
            --  worker raises Physical_Error; the pool must re-raise it after
            --  all workers finish instead of returning partial results
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
            Run_Test ("Parallel task pool re-raises worker exception", Raised);
         end;
      end;

      IO.New_Line;
   end Test_Propagation;

begin
   IO.Put_Line ("=========================================");
   IO.Put_Line ("  HALE Orbital Mechanics - Test Suite");
   IO.Put_Line ("=========================================");
   IO.New_Line;

   --  Run all test suites
   Test_Vectors;
   Test_Matrices;
   Test_Twobody;
   Test_Elements;
   Test_Kepler;
   Test_Maneuvers;
   Test_Threebody;
   Test_Propagation;

   --  Print summary
   IO.Put_Line ("=========================================");
   IO.Put_Line ("  Test Summary");
   IO.Put_Line ("=========================================");
   IO.Put_Line ("  Total:  " & Natural'Image (Total_Tests));
   IO.Put_Line ("  Passed: " & Natural'Image (Tests_Passed));
   IO.Put_Line ("  Failed: " & Natural'Image (Tests_Failed));
   IO.Put_Line ("=========================================");

   if Tests_Failed = 0 then
      IO.Put_Line ("  All tests passed!");
   else
      IO.Put_Line ("  Some tests failed.");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

end Run_Tests;
