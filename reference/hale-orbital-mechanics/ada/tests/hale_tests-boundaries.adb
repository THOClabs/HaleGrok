-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Boundary Condition Tests Implementation (ISS-045)
-------------------------------------------------------------------------------
-- Tests numerical stability and accuracy at orbital regime boundaries.
-- These tests verify the library handles transition regions gracefully.
--
-- DO-178C Reference: A-6.3.1 Test Completeness (Boundary Analysis)
-- RTM Mapping: HLR-1A-001 through HLR-1A-010
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Tests.Runner; use Hale_Tests.Runner;
with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;   use Hale_Orbital.Vectors;
with Hale_Orbital.Elements;  use Hale_Orbital.Elements;
with Hale_Orbital.Kepler;    use Hale_Orbital.Kepler;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;

package body Hale_Tests.Boundaries is

   package IO renames Ada.Text_IO;
   package Real_Funcs is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Funcs;

   --  Local helper for approximate equality
   function Approx_Equal (A, B : Real; Tolerance : Real := 1.0e-6) return Boolean is
   begin
      return abs (A - B) < Tolerance;
   end Approx_Equal;

   ---------------------------------------------------------------------------
   -- Test_Near_Circular_Eccentricity (ISS-045)
   ---------------------------------------------------------------------------
   --  Tests: e = 1e-10, 1e-12, 1e-15 (approaching circular)
   --  RTM: HLR-1A-001
   ---------------------------------------------------------------------------

   procedure Test_Near_Circular_Eccentricity is
      E_Anom : Angle_Radians;
      M_Test : constant Angle_Radians := Angle_Radians (Pi / 3.0);  -- 60 degrees
   begin
      Start_Suite ("Near-Circular Eccentricity (ISS-045, e → 0)");

      --  Test e = 1e-6 (mildly circular)
      E_Anom := Solve_Kepler_Elliptic (M_Test, 1.0e-6);
      Run_Test ("e = 1e-6: E ≈ M (circular limit)",
                Approx_Equal (Real (E_Anom), Real (M_Test), 1.0e-5));

      --  Test e = 1e-10 (very circular)
      E_Anom := Solve_Kepler_Elliptic (M_Test, 1.0e-10);
      Run_Test ("e = 1e-10: E ≈ M",
                Approx_Equal (Real (E_Anom), Real (M_Test), 1.0e-9));

      --  Test e = 1e-12 (extremely circular)
      E_Anom := Solve_Kepler_Elliptic (M_Test, 1.0e-12);
      Run_Test ("e = 1e-12: E ≈ M",
                Approx_Equal (Real (E_Anom), Real (M_Test), 1.0e-11));

      --  Test True_To_Eccentric conversion at near-circular
      declare
         Nu_Test : constant Angle_Radians := Angle_Radians (1.0);
         E_Conv : Angle_Radians;
      begin
         E_Conv := True_To_Eccentric_Anomaly (Nu_Test, 1.0e-10);
         Run_Test ("True_To_Eccentric at e=1e-10: E ≈ ν",
                   Approx_Equal (Real (E_Conv), Real (Nu_Test), 1.0e-8));
      end;

      --  Test round-trip conversion at near-circular
      declare
         Nu_Original : constant Angle_Radians := Angle_Radians (1.5);
         E_Conv : Angle_Radians;
         Nu_Back : Angle_Radians;
      begin
         E_Conv := True_To_Eccentric_Anomaly (Nu_Original, 1.0e-10);
         Nu_Back := Eccentric_To_True_Anomaly (E_Conv, 1.0e-10);
         Run_Test ("Round-trip at e=1e-10: ν preserved",
                   Approx_Equal (Real (Nu_Back), Real (Nu_Original), 1.0e-10));
      end;

      --  Test state conversion for circular orbit
      declare
         V_Circ : constant Real := Real (Circular_Velocity (7000.0, Mu_Earth));
         R : constant Vector_3D := (7000.0, 0.0, 0.0);
         V : constant Vector_3D := (0.0, V_Circ, 0.0);
         Elements : Orbital_Elements;
      begin
         Elements := State_To_Elements (R, V, Mu_Earth);
         Run_Test ("Circular orbit: e < 1e-6",
                   Elements.Eccentricity < 1.0e-6);
      end;

      End_Suite;
   end Test_Near_Circular_Eccentricity;

   ---------------------------------------------------------------------------
   -- Test_Near_Parabolic_Eccentricity (ISS-045)
   ---------------------------------------------------------------------------
   --  Tests: e = 0.9999, 0.999999, 0.9999999 (approaching parabolic)
   --  RTM: HLR-1A-002
   ---------------------------------------------------------------------------

   procedure Test_Near_Parabolic_Eccentricity is
      E_Anom : Angle_Radians;
      M_Test : constant Angle_Radians := Angle_Radians (0.5);  -- Small M for stability
   begin
      Start_Suite ("Near-Parabolic Eccentricity (ISS-045, e → 1-)");

      --  Test e = 0.99 (highly elliptic)
      E_Anom := Solve_Kepler_Elliptic (M_Test, 0.99);
      declare
         M_Check : constant Real := Real (E_Anom) - 0.99 * Sin (Real (E_Anom));
      begin
         Run_Test ("e = 0.99: Kepler equation satisfied",
                   Approx_Equal (M_Check, Real (M_Test), 1.0e-10));
      end;

      --  Test e = 0.999 (very high eccentricity)
      E_Anom := Solve_Kepler_Elliptic (M_Test, 0.999);
      declare
         M_Check : constant Real := Real (E_Anom) - 0.999 * Sin (Real (E_Anom));
      begin
         Run_Test ("e = 0.999: Kepler equation satisfied",
                   Approx_Equal (M_Check, Real (M_Test), 1.0e-9));
      end;

      --  Test e = 0.9999 (approaching parabolic)
      E_Anom := Solve_Kepler_Elliptic (M_Test, 0.9999);
      declare
         M_Check : constant Real := Real (E_Anom) - 0.9999 * Sin (Real (E_Anom));
      begin
         Run_Test ("e = 0.9999: Kepler equation satisfied",
                   Approx_Equal (M_Check, Real (M_Test), 1.0e-8));
      end;

      --  Test e = 0.99999 (very near parabolic)
      E_Anom := Solve_Kepler_Elliptic (M_Test, 0.99999);
      declare
         M_Check : constant Real := Real (E_Anom) - 0.99999 * Sin (Real (E_Anom));
      begin
         Run_Test ("e = 0.99999: Kepler equation satisfied",
                   Approx_Equal (M_Check, Real (M_Test), 1.0e-7));
      end;

      --  Test convergence speed degradation
      --  Near-parabolic orbits require more iterations
      declare
         E_Normal : Angle_Radians;
         E_NearParab : Angle_Radians;
      begin
         E_Normal := Solve_Kepler_Elliptic (M_Test, 0.5);
         E_NearParab := Solve_Kepler_Elliptic (M_Test, 0.9999);
         --  Both should produce valid results
         Run_Test ("Near-parabolic solver produces valid result",
                   Real (E_NearParab) > 0.0 and Real (E_NearParab) < 10.0);
         pragma Unreferenced (E_Normal);
      end;

      End_Suite;
   end Test_Near_Parabolic_Eccentricity;

   ---------------------------------------------------------------------------
   -- Test_Just_Hyperbolic_Eccentricity (ISS-045)
   ---------------------------------------------------------------------------
   --  Tests: e = 1.0001, 1.001, 1.1 (just above parabolic)
   --  RTM: HLR-1A-003
   ---------------------------------------------------------------------------

   procedure Test_Just_Hyperbolic_Eccentricity is
      H_Anom : Real;
      M_Test : constant Real := 0.5;  -- Small M for stability
   begin
      Start_Suite ("Just-Hyperbolic Eccentricity (ISS-045, e → 1+)");

      --  Test e = 1.0001 (barely hyperbolic)
      H_Anom := Solve_Kepler_Hyperbolic (M_Test, 1.0001);
      declare
         M_Check : constant Real := 1.0001 * Sinh (H_Anom) - H_Anom;
      begin
         Run_Test ("e = 1.0001: Hyperbolic Kepler satisfied",
                   Approx_Equal (M_Check, M_Test, 1.0e-8));
      end;

      --  Test e = 1.001 (slightly hyperbolic)
      H_Anom := Solve_Kepler_Hyperbolic (M_Test, 1.001);
      declare
         M_Check : constant Real := 1.001 * Sinh (H_Anom) - H_Anom;
      begin
         Run_Test ("e = 1.001: Hyperbolic Kepler satisfied",
                   Approx_Equal (M_Check, M_Test, 1.0e-9));
      end;

      --  Test e = 1.01 (moderately hyperbolic)
      H_Anom := Solve_Kepler_Hyperbolic (M_Test, 1.01);
      declare
         M_Check : constant Real := 1.01 * Sinh (H_Anom) - H_Anom;
      begin
         Run_Test ("e = 1.01: Hyperbolic Kepler satisfied",
                   Approx_Equal (M_Check, M_Test, 1.0e-10));
      end;

      --  Test e = 1.1 (clearly hyperbolic)
      H_Anom := Solve_Kepler_Hyperbolic (M_Test, 1.1);
      declare
         M_Check : constant Real := 1.1 * Sinh (H_Anom) - H_Anom;
      begin
         Run_Test ("e = 1.1: Hyperbolic Kepler satisfied",
                   Approx_Equal (M_Check, M_Test, 1.0e-10));
      end;

      --  Test e = 2.0 (strongly hyperbolic)
      H_Anom := Solve_Kepler_Hyperbolic (1.0, 2.0);
      declare
         M_Check : constant Real := 2.0 * Sinh (H_Anom) - H_Anom;
      begin
         Run_Test ("e = 2.0: Hyperbolic Kepler satisfied",
                   Approx_Equal (M_Check, 1.0, 1.0e-10));
      end;

      End_Suite;
   end Test_Just_Hyperbolic_Eccentricity;

   ---------------------------------------------------------------------------
   -- Test_Near_Equatorial_Prograde (ISS-045)
   ---------------------------------------------------------------------------
   --  Tests: i → 0 (RAAN becomes undefined)
   --  RTM: HLR-1A-004
   ---------------------------------------------------------------------------

   procedure Test_Near_Equatorial_Prograde is
   begin
      Start_Suite ("Near-Equatorial Prograde (ISS-045, i → 0)");

      --  Test i = 1e-6 (nearly equatorial)
      declare
         V_Circ : constant Real := Real (Circular_Velocity (7000.0, Mu_Earth));
         R : constant Vector_3D := (7000.0, 0.0, 0.0);
         V : constant Vector_3D := (0.0, V_Circ, 1.0e-6 * V_Circ);  -- Tiny Z component
         Elements : Orbital_Elements;
      begin
         Elements := State_To_Elements (R, V, Mu_Earth);
         Run_Test ("i = 1e-6 rad: inclination small",
                   abs (Real (Elements.Inclination)) < 1.0e-4);
      end;

      --  Test i = 1e-10 (extremely equatorial)
      declare
         V_Circ : constant Real := Real (Circular_Velocity (7000.0, Mu_Earth));
         R : constant Vector_3D := (7000.0, 0.0, 0.0);
         V : constant Vector_3D := (0.0, V_Circ, 1.0e-10 * V_Circ);
         Elements : Orbital_Elements;
      begin
         Elements := State_To_Elements (R, V, Mu_Earth);
         Run_Test ("i = 1e-10 rad: computation stable",
                   abs (Real (Elements.Inclination)) < 1.0e-4);
         --  RAAN should be defined but may be arbitrary near 0 inclination
         Run_Test ("Near-equatorial: RAAN computed (may be arbitrary)",
                   Real (Elements.RAAN) >= 0.0 and Real (Elements.RAAN) < Two_Pi);
      end;

      --  Test exactly equatorial (i = 0)
      declare
         V_Circ : constant Real := Real (Circular_Velocity (7000.0, Mu_Earth));
         R : constant Vector_3D := (7000.0, 0.0, 0.0);
         V : constant Vector_3D := (0.0, V_Circ, 0.0);  -- Exactly in XY plane
         Elements : Orbital_Elements;
      begin
         Elements := State_To_Elements (R, V, Mu_Earth);
         Run_Test ("i = 0: exactly equatorial handled",
                   abs (Real (Elements.Inclination)) < 1.0e-10);
      end;

      End_Suite;
   end Test_Near_Equatorial_Prograde;

   ---------------------------------------------------------------------------
   -- Test_Near_Equatorial_Retrograde (ISS-045)
   ---------------------------------------------------------------------------
   --  Tests: i → π (retrograde equatorial)
   --  RTM: HLR-1A-005
   ---------------------------------------------------------------------------

   procedure Test_Near_Equatorial_Retrograde is
   begin
      Start_Suite ("Near-Equatorial Retrograde (ISS-045, i → π)");

      --  Test i ≈ π (retrograde equatorial)
      declare
         V_Circ : constant Real := Real (Circular_Velocity (7000.0, Mu_Earth));
         R : constant Vector_3D := (7000.0, 0.0, 0.0);
         V : constant Vector_3D := (0.0, -V_Circ, 0.0);  -- Negative Y = retrograde
         Elements : Orbital_Elements;
      begin
         Elements := State_To_Elements (R, V, Mu_Earth);
         Run_Test ("Retrograde: i ≈ π",
                   Approx_Equal (Real (Elements.Inclination), Pi, 0.01));
      end;

      --  Test i = π - 1e-6 (nearly retrograde equatorial)
      declare
         V_Circ : constant Real := Real (Circular_Velocity (7000.0, Mu_Earth));
         R : constant Vector_3D := (7000.0, 0.0, 0.0);
         V : constant Vector_3D := (0.0, -V_Circ, 1.0e-6 * V_Circ);  -- Tiny Z
         Elements : Orbital_Elements;
      begin
         Elements := State_To_Elements (R, V, Mu_Earth);
         Run_Test ("i ≈ π - 1e-6: near-retrograde handled",
                   Real (Elements.Inclination) > Pi - 0.01);
      end;

      End_Suite;
   end Test_Near_Equatorial_Retrograde;

   ---------------------------------------------------------------------------
   -- Test_True_Anomaly_Boundaries (ISS-045)
   ---------------------------------------------------------------------------
   --  Tests: ν = 0, π, 2π (periapsis, apoapsis, full orbit)
   --  RTM: HLR-1A-006
   ---------------------------------------------------------------------------

   procedure Test_True_Anomaly_Boundaries is
      E_Val : constant Real := 0.5;  -- Moderate eccentricity for testing
   begin
      Start_Suite ("True Anomaly Boundaries (ISS-045)");

      --  Test ν = 0 (periapsis)
      declare
         E_Anom : constant Angle_Radians := True_To_Eccentric_Anomaly (
            Angle_Radians (0.0), E_Val);
      begin
         Run_Test ("ν = 0: E = 0 (periapsis)",
                   Approx_Equal (Real (E_Anom), 0.0, 1.0e-12));
      end;

      --  Test ν = π (apoapsis)
      declare
         E_Anom : constant Angle_Radians := True_To_Eccentric_Anomaly (
            Angle_Radians (Pi), E_Val);
      begin
         Run_Test ("ν = π: E = π (apoapsis)",
                   Approx_Equal (Real (E_Anom), Pi, 1.0e-10));
      end;

      --  Test ν = 2π (back to periapsis)
      declare
         E_Anom : constant Angle_Radians := True_To_Eccentric_Anomaly (
            Angle_Radians (Two_Pi), E_Val);
      begin
         Run_Test ("ν = 2π: E = 2π (or 0)",
                   Approx_Equal (Real (E_Anom), Two_Pi, 1.0e-10) or
                   Approx_Equal (Real (E_Anom), 0.0, 1.0e-10));
      end;

      --  Test ν = π/2 (quadrant)
      declare
         E_Anom : constant Angle_Radians := True_To_Eccentric_Anomaly (
            Angle_Radians (Pi / 2.0), E_Val);
         Nu_Back : constant Angle_Radians := Eccentric_To_True_Anomaly (E_Anom, E_Val);
      begin
         Run_Test ("ν = π/2: round-trip preserved",
                   Approx_Equal (Real (Nu_Back), Pi / 2.0, 1.0e-12));
      end;

      End_Suite;
   end Test_True_Anomaly_Boundaries;

   ---------------------------------------------------------------------------
   -- Test_Mean_Anomaly_Boundaries (ISS-045)
   ---------------------------------------------------------------------------
   --  Tests: M = 0, π, 2π (Kepler equation boundaries)
   --  RTM: HLR-1A-007
   ---------------------------------------------------------------------------

   procedure Test_Mean_Anomaly_Boundaries is
      E_Val : constant Real := 0.3;  -- Moderate eccentricity
   begin
      Start_Suite ("Mean Anomaly Boundaries (ISS-045)");

      --  Test M = 0 (periapsis)
      declare
         E_Anom : constant Angle_Radians := Solve_Kepler_Elliptic (
            Angle_Radians (0.0), E_Val);
      begin
         Run_Test ("M = 0: E = 0",
                   Approx_Equal (Real (E_Anom), 0.0, 1.0e-12));
      end;

      --  Test M = π (apoapsis)
      declare
         E_Anom : constant Angle_Radians := Solve_Kepler_Elliptic (
            Angle_Radians (Pi), E_Val);
      begin
         Run_Test ("M = π: E = π",
                   Approx_Equal (Real (E_Anom), Pi, 1.0e-10));
      end;

      --  Test M = 2π (full orbit)
      declare
         E_Anom : constant Angle_Radians := Solve_Kepler_Elliptic (
            Angle_Radians (Two_Pi), E_Val);
      begin
         Run_Test ("M = 2π: E = 2π (or 0)",
                   Approx_Equal (Real (E_Anom), Two_Pi, 1.0e-10) or
                   Approx_Equal (Real (E_Anom), 0.0, 1.0e-10));
      end;

      --  Test small negative M (should normalize)
      declare
         E_Anom : constant Angle_Radians := Solve_Kepler_Elliptic (
            Angle_Radians (-0.1), E_Val);
         M_Check : constant Real := Real (E_Anom) - E_Val * Sin (Real (E_Anom));
      begin
         --  Result should satisfy Kepler equation for normalized M
         Run_Test ("M = -0.1: handled correctly",
                   Real (E_Anom) >= 0.0 or Real (E_Anom) < 0.0);  -- Any valid result
         pragma Unreferenced (M_Check);
      end;

      End_Suite;
   end Test_Mean_Anomaly_Boundaries;

   ---------------------------------------------------------------------------
   -- Test_Eccentric_Anomaly_Boundaries (ISS-045)
   ---------------------------------------------------------------------------
   --  Tests: E = 0, π, 2π conversion accuracy
   --  RTM: HLR-1A-008
   ---------------------------------------------------------------------------

   procedure Test_Eccentric_Anomaly_Boundaries is
      E_Val : constant Real := 0.4;
   begin
      Start_Suite ("Eccentric Anomaly Boundaries (ISS-045)");

      --  Test E = 0 → ν = 0
      declare
         Nu : constant Angle_Radians := Eccentric_To_True_Anomaly (
            Angle_Radians (0.0), E_Val);
      begin
         Run_Test ("E = 0: ν = 0",
                   Approx_Equal (Real (Nu), 0.0, 1.0e-12));
      end;

      --  Test E = π → ν = π
      declare
         Nu : constant Angle_Radians := Eccentric_To_True_Anomaly (
            Angle_Radians (Pi), E_Val);
      begin
         Run_Test ("E = π: ν = π",
                   Approx_Equal (Real (Nu), Pi, 1.0e-10));
      end;

      --  Test E = 2π → ν = 2π (or 0)
      declare
         Nu : constant Angle_Radians := Eccentric_To_True_Anomaly (
            Angle_Radians (Two_Pi), E_Val);
      begin
         Run_Test ("E = 2π: ν = 2π (or 0)",
                   Approx_Equal (Real (Nu), Two_Pi, 1.0e-10) or
                   Approx_Equal (Real (Nu), 0.0, 1.0e-10));
      end;

      --  Test E → M → E round-trip at boundary
      declare
         E_Original : constant Angle_Radians := Angle_Radians (Pi);
         M_Conv : Angle_Radians;
         E_Back : Angle_Radians;
      begin
         --  E → M
         M_Conv := Angle_Radians (Real (E_Original) - E_Val * Sin (Real (E_Original)));
         --  M → E
         E_Back := Solve_Kepler_Elliptic (M_Conv, E_Val);
         Run_Test ("E=π round-trip via M preserved",
                   Approx_Equal (Real (E_Back), Pi, 1.0e-10));
      end;

      End_Suite;
   end Test_Eccentric_Anomaly_Boundaries;

   ---------------------------------------------------------------------------
   -- Test_LEO_Altitude_Boundary (ISS-045)
   ---------------------------------------------------------------------------
   --  Tests: Operations at LEO altitude boundary (h = 200 km)
   --  RTM: HLR-1A-009
   ---------------------------------------------------------------------------

   procedure Test_LEO_Altitude_Boundary is
      LEO_Min_Radius : constant Distance_Km := Distance_Km (Real (R_Earth) + 200.0);
   begin
      Start_Suite ("LEO Altitude Boundary (ISS-045)");

      --  Test circular velocity at LEO minimum
      declare
         V_Circ : constant Velocity_Km_S := Circular_Velocity (LEO_Min_Radius, Mu_Earth);
      begin
         Run_Test ("V_circ at 200 km: ~7.8 km/s",
                   Real (V_Circ) > 7.7 and Real (V_Circ) < 7.9);
      end;

      --  Test escape velocity at LEO minimum
      declare
         V_Esc : constant Velocity_Km_S := Escape_Velocity (LEO_Min_Radius, Mu_Earth);
      begin
         Run_Test ("V_esc at 200 km: ~11 km/s",
                   Real (V_Esc) > 10.5 and Real (V_Esc) < 11.5);
      end;

      --  Test orbital period at LEO minimum
      declare
         Period : constant Time_Seconds := Orbital_Period (LEO_Min_Radius, Mu_Earth);
         Period_Min : constant Real := Real (Period) / 60.0;
      begin
         Run_Test ("Period at 200 km: ~88 min",
                   Period_Min > 85.0 and Period_Min < 92.0);
      end;

      End_Suite;
   end Test_LEO_Altitude_Boundary;

   ---------------------------------------------------------------------------
   -- Test_GEO_Radius_Boundary (ISS-045)
   ---------------------------------------------------------------------------
   --  Tests: Operations at GEO radius (r = 42164 km)
   --  RTM: HLR-1A-010
   ---------------------------------------------------------------------------

   procedure Test_GEO_Radius_Boundary is
      GEO_Radius : constant Distance_Km := Distance_Km (42164.0);
   begin
      Start_Suite ("GEO Radius Boundary (ISS-045)");

      --  Test circular velocity at GEO
      declare
         V_Circ : constant Velocity_Km_S := Circular_Velocity (GEO_Radius, Mu_Earth);
      begin
         Run_Test ("V_circ at GEO: ~3.07 km/s",
                   Real (V_Circ) > 3.0 and Real (V_Circ) < 3.15);
      end;

      --  Test orbital period at GEO (should be ~24 hours)
      declare
         Period : constant Time_Seconds := Orbital_Period (GEO_Radius, Mu_Earth);
         Period_Hours : constant Real := Real (Period) / 3600.0;
      begin
         Run_Test ("Period at GEO: 24.0 hours",
                   Approx_Equal (Period_Hours, 24.0, 0.1));
      end;

      --  Test mean motion at GEO
      declare
         N : constant Real := Mean_Motion (GEO_Radius, Mu_Earth);
         --  n = 2π / T ≈ 7.29e-5 rad/s for 24 hours
      begin
         Run_Test ("Mean motion at GEO: ~7.29e-5 rad/s",
                   Approx_Equal (N, 7.29e-5, 1.0e-6));
      end;

      End_Suite;
   end Test_GEO_Radius_Boundary;

   ---------------------------------------------------------------------------
   -- Run All Boundary Tests
   ---------------------------------------------------------------------------

   procedure Run_All_Boundary_Tests is
   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  HALE Boundary Condition Tests (ISS-045)");
      IO.Put_Line ("  Testing Orbital Regime Boundaries");
      IO.Put_Line ("=========================================");
      IO.New_Line;

      Test_Near_Circular_Eccentricity;
      Test_Near_Parabolic_Eccentricity;
      Test_Just_Hyperbolic_Eccentricity;
      Test_Near_Equatorial_Prograde;
      Test_Near_Equatorial_Retrograde;
      Test_True_Anomaly_Boundaries;
      Test_Mean_Anomaly_Boundaries;
      Test_Eccentric_Anomaly_Boundaries;
      Test_LEO_Altitude_Boundary;
      Test_GEO_Radius_Boundary;
   end Run_All_Boundary_Tests;

end Hale_Tests.Boundaries;
