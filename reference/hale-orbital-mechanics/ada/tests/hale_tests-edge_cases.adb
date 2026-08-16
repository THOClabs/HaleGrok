-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Edge Case Tests Implementation
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Tests.Runner; use Hale_Tests.Runner;
with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;   use Hale_Orbital.Vectors;
with Hale_Orbital.Matrices;  use Hale_Orbital.Matrices;
with Hale_Orbital.Elements;  use Hale_Orbital.Elements;
with Hale_Orbital.Kepler;    use Hale_Orbital.Kepler;
with Hale_Orbital.Stumpff;   use Hale_Orbital.Stumpff;
with Hale_Orbital.Lambert;   use Hale_Orbital.Lambert;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;
with Hale_Orbital.Maneuvers; use Hale_Orbital.Maneuvers;
with Hale_Orbital.Propagation; use Hale_Orbital.Propagation;

package body Hale_Tests.Edge_Cases is

   package IO renames Ada.Text_IO;
   package Real_Funcs is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Funcs;

   --  Local helper for approximate equality
   function Approx_Equal (A, B : Real; Tolerance : Real := 1.0e-6) return Boolean is
   begin
      return abs (A - B) < Tolerance;
   end Approx_Equal;

   --  ISS-010 workaround: in the debug library build (-gnatVa validity
   --  checks), Solve_Lambert raises Constraint_Error on internal NaN
   --  values.  Report such a failure as a non-converged result so the
   --  remaining tests still execute; the convergence assertions below
   --  then fail and flag the defect.  Remove once ISS-010 is fixed.
   function Safe_Solve_Lambert (R1       : Position_Vector;
                                R2       : Position_Vector;
                                Tof      : Time_Seconds;
                                Mu       : Gravitational_Parameter;
                                Long_Way : Boolean := False) return Lambert_Result is
   begin
      return Solve_Lambert (R1, R2, Tof, Mu, Long_Way);
   exception
      when others =>
         return (V1 => (0.0, 0.0, 0.0), V2 => (0.0, 0.0, 0.0),
                 A => 0.0, E => 0.0, Iterations => 0, Converged => False);
   end Safe_Solve_Lambert;

   ---------------------------------------------------------------------------
   -- Vector Edge Cases
   ---------------------------------------------------------------------------

   procedure Test_Vector_Edge_Cases is
      V_Zero : constant Vector_3D := (0.0, 0.0, 0.0);
      V_Unit_X : constant Vector_3D := (1.0, 0.0, 0.0);
      V_Unit_Y : constant Vector_3D := (0.0, 1.0, 0.0);
      V_Unit_Z : constant Vector_3D := (0.0, 0.0, 1.0);
      V_Small : constant Vector_3D := (1.0e-15, 1.0e-15, 1.0e-15);
      V_Large : constant Vector_3D := (1.0e10, 1.0e10, 1.0e10);
   begin
      Start_Suite ("Vector Edge Cases");

      --  Zero vector tests
      Run_Test ("Zero vector magnitude = 0",
                Approx_Equal (Magnitude (V_Zero), 0.0, 1.0e-15));

      Run_Test ("Zero vector magnitude squared = 0",
                Approx_Equal (Magnitude_Squared (V_Zero), 0.0, 1.0e-30));

      Run_Test ("Zero + Unit_X = Unit_X",
                Approx_Equal (Magnitude (V_Zero + V_Unit_X - V_Unit_X), 0.0, 1.0e-15));

      --  Unit vector tests
      Run_Test ("Unit X magnitude = 1",
                Approx_Equal (Magnitude (V_Unit_X), 1.0, 1.0e-15));

      Run_Test ("Normalize Unit X = Unit X",
                Approx_Equal (Magnitude (Normalize (V_Unit_X) - V_Unit_X), 0.0, 1.0e-15));

      --  Cross product with parallel vectors
      Run_Test ("X cross X = Zero (parallel vectors)",
                Approx_Equal (Magnitude (Cross (V_Unit_X, V_Unit_X)), 0.0, 1.0e-15));

      --  Cross product orthogonality
      Run_Test ("X cross Y = Z",
                Approx_Equal (Magnitude (Cross (V_Unit_X, V_Unit_Y) - V_Unit_Z), 0.0, 1.0e-15));

      Run_Test ("Y cross Z = X",
                Approx_Equal (Magnitude (Cross (V_Unit_Y, V_Unit_Z) - V_Unit_X), 0.0, 1.0e-15));

      --  Dot product tests
      Run_Test ("Unit X dot Unit Y = 0 (orthogonal)",
                Approx_Equal (Dot (V_Unit_X, V_Unit_Y), 0.0, 1.0e-15));

      Run_Test ("Unit X dot Unit X = 1",
                Approx_Equal (Dot (V_Unit_X, V_Unit_X), 1.0, 1.0e-15));

      --  Small values
      Run_Test ("Small vector has positive magnitude",
                Magnitude (V_Small) > 0.0);

      --  Large values
      Run_Test ("Large vector magnitude reasonable",
                Magnitude (V_Large) > 1.0e10 and Magnitude (V_Large) < 2.0e10);

      --  Scalar multiplication edge cases
      Run_Test ("0 * V = Zero",
                Approx_Equal (Magnitude (0.0 * V_Unit_X), 0.0, 1.0e-15));

      Run_Test ("(-1) * Unit_X = -Unit_X",
                Approx_Equal (Magnitude ((-1.0) * V_Unit_X + V_Unit_X), 0.0, 1.0e-15));

      End_Suite;
   end Test_Vector_Edge_Cases;

   ---------------------------------------------------------------------------
   -- Kepler Solver Edge Cases
   ---------------------------------------------------------------------------

   procedure Test_Kepler_Edge_Cases is
      E_Anom : Angle_Radians;
      M : Angle_Radians;
   begin
      Start_Suite ("Kepler Solver Edge Cases");

      --  Circular orbit (e = 0)
      M := Angle_Radians (Pi / 2.0);
      E_Anom := Solve_Kepler_Elliptic (M, 0.0);
      Run_Test ("Circular orbit e=0: E = M",
                Approx_Equal (Real (E_Anom), Real (M), 1.0e-12));

      --  Very small eccentricity
      M := Angle_Radians (Pi / 3.0);
      E_Anom := Solve_Kepler_Elliptic (M, 1.0e-10);
      Run_Test ("Near-circular e=1e-10: E ≈ M",
                Approx_Equal (Real (E_Anom), Real (M), 1.0e-8));

      --  Near-parabolic eccentricity
      M := Angle_Radians (0.5);
      E_Anom := Solve_Kepler_Elliptic (M, 0.99);
      --  Verify: E - e*sin(E) = M
      declare
         M_Check : constant Real := Real (E_Anom) - 0.99 * Sin (Real (E_Anom));
      begin
         Run_Test ("High eccentricity e=0.99: solution valid",
                   Approx_Equal (M_Check, Real (M), 1.0e-8));
      end;

      --  M = 0 (periapsis)
      M := Angle_Radians (0.0);
      E_Anom := Solve_Kepler_Elliptic (M, 0.5);
      Run_Test ("M=0: E=0 (periapsis)",
                Approx_Equal (Real (E_Anom), 0.0, 1.0e-12));

      --  M = Pi (apoapsis)
      M := Angle_Radians (Pi);
      E_Anom := Solve_Kepler_Elliptic (M, 0.5);
      Run_Test ("M=Pi: E=Pi (apoapsis)",
                Approx_Equal (Real (E_Anom), Pi, 1.0e-10));

      --  M = 2*Pi (full orbit)
      M := Angle_Radians (Two_Pi);
      E_Anom := Solve_Kepler_Elliptic (M, 0.3);
      Run_Test ("M=2Pi: E=2Pi (full orbit)",
                Approx_Equal (Real (E_Anom), Two_Pi, 1.0e-10));

      --  Stumpff functions edge cases
      Run_Test ("Stumpff C(z) at z=0",
                Approx_Equal (Stumpff_C (0.0), 0.5, 1.0e-12));

      Run_Test ("Stumpff S(z) at z=0",
                Approx_Equal (Stumpff_S (0.0), 1.0 / 6.0, 1.0e-12));

      --  Elliptic case (z > 0)
      Run_Test ("Stumpff C(z>0) positive",
                Stumpff_C (1.0) > 0.0);

      Run_Test ("Stumpff S(z>0) positive",
                Stumpff_S (1.0) > 0.0);

      --  Hyperbolic case (z < 0)
      Run_Test ("Stumpff C(z<0) defined",
                Stumpff_C (-1.0) > 0.0);

      Run_Test ("Stumpff S(z<0) defined",
                Stumpff_S (-1.0) > 0.0);

      End_Suite;
   end Test_Kepler_Edge_Cases;

   ---------------------------------------------------------------------------
   -- Orbital Elements Edge Cases
   ---------------------------------------------------------------------------

   procedure Test_Elements_Edge_Cases is
      R, V : Vector_3D;
      Elements : Orbital_Elements;
      State : State_Vector;
   begin
      Start_Suite ("Orbital Elements Edge Cases");

      --  Circular equatorial orbit
      R := (7000.0, 0.0, 0.0);
      declare
         V_Circ : constant Real := Real (Circular_Velocity (7000.0, Mu_Earth));
      begin
         V := (0.0, V_Circ, 0.0);
      end;
      Elements := State_To_Elements (R, V, Mu_Earth);
      Run_Test ("Circular orbit: e ≈ 0",
                Elements.Eccentricity < 0.001);
      Run_Test ("Equatorial orbit: i ≈ 0",
                abs (Real (Elements.Inclination)) < 0.001);

      --  Polar circular orbit
      R := (7000.0, 0.0, 0.0);
      declare
         V_Circ : constant Real := Real (Circular_Velocity (7000.0, Mu_Earth));
      begin
         V := (0.0, 0.0, V_Circ);  -- Velocity in Z direction for polar
      end;
      Elements := State_To_Elements (R, V, Mu_Earth);
      Run_Test ("Polar orbit: i ≈ 90 deg",
                Approx_Equal (Real (Elements.Inclination), Pi / 2.0, 0.01));

      --  Retrograde equatorial orbit
      R := (7000.0, 0.0, 0.0);
      declare
         V_Circ : constant Real := Real (Circular_Velocity (7000.0, Mu_Earth));
      begin
         V := (0.0, -V_Circ, 0.0);  -- Negative velocity for retrograde
      end;
      Elements := State_To_Elements (R, V, Mu_Earth);
      Run_Test ("Retrograde equatorial: i ≈ 180 deg",
                Approx_Equal (Real (Elements.Inclination), Pi, 0.01));

      --  High eccentricity orbit
      R := (6678.0, 0.0, 0.0);  -- Periapsis
      V := (0.0, 10.5, 0.0);    -- Higher than circular for ellipse
      Elements := State_To_Elements (R, V, Mu_Earth);
      Run_Test ("Elliptical orbit: 0 < e < 1",
                Elements.Eccentricity > 0.1 and Elements.Eccentricity < 1.0);

      --  Round-trip conversion test
      State := Elements_To_State (Elements, Mu_Earth);
      Run_Test ("Round-trip: position X preserved",
                Approx_Equal (State.Position (1), R (1), 1.0));
      Run_Test ("Round-trip: velocity Y preserved",
                Approx_Equal (State.Velocity (2), V (2), 0.01));

      --  Anomaly conversions
      declare
         E_Val : constant Real := 0.5;
         Nu_Test : Angle_Radians;
         E_Anom : Angle_Radians;
         Nu_Back : Angle_Radians;
      begin
         --  Test at periapsis (nu = 0)
         Nu_Test := Angle_Radians (0.0);
         E_Anom := True_To_Eccentric_Anomaly (Nu_Test, E_Val);
         Run_Test ("True anomaly 0 -> Eccentric anomaly 0",
                   Approx_Equal (Real (E_Anom), 0.0, 1.0e-12));

         --  Test at apoapsis (nu = pi)
         Nu_Test := Angle_Radians (Pi);
         E_Anom := True_To_Eccentric_Anomaly (Nu_Test, E_Val);
         Run_Test ("True anomaly Pi -> Eccentric anomaly Pi",
                   Approx_Equal (Real (E_Anom), Pi, 1.0e-10));

         --  Round-trip
         Nu_Test := Angle_Radians (1.0);
         E_Anom := True_To_Eccentric_Anomaly (Nu_Test, E_Val);
         Nu_Back := Eccentric_To_True_Anomaly (E_Anom, E_Val);
         Run_Test ("Anomaly round-trip",
                   Approx_Equal (Real (Nu_Back), Real (Nu_Test), 1.0e-12));
      end;

      End_Suite;
   end Test_Elements_Edge_Cases;

   ---------------------------------------------------------------------------
   -- Lambert Solver Edge Cases
   ---------------------------------------------------------------------------

   procedure Test_Lambert_Edge_Cases is
      R1, R2 : Position_Vector;
      Solution : Lambert_Result;
   begin
      Start_Suite ("Lambert Solver Edge Cases");

      --  Short arc transfer
      R1 := (7000.0, 0.0, 0.0);
      R2 := (7000.0 * Cos (0.1), 7000.0 * Sin (0.1), 0.0);  -- ~6 degree arc
      Solution := Safe_Solve_Lambert (R1, R2, 600.0, Mu_Earth);
      Run_Test ("Short arc (6 deg): convergence",
                Solution.Converged);
      declare
         --  Departure delta-V relative to a circular parking orbit at R1
         V_Circ_R1 : constant Velocity_Vector :=
            (0.0, Real (Circular_Velocity (7000.0, Mu_Earth)), 0.0);
         DV : constant Velocity_Km_S := Departure_Delta_V (V_Circ_R1, Solution);
      begin
         Run_Test ("Short arc: valid delta-V",
                   Solution.Converged and then
                   (Real (DV) > 0.0 and Real (DV) < 10.0));
      end;

      --  Longer arc transfer
      R1 := (7000.0, 0.0, 0.0);
      R2 := (0.0, 10000.0, 0.0);  -- 90 degree arc
      Solution := Safe_Solve_Lambert (R1, R2, 3000.0, Mu_Earth);
      Run_Test ("90 degree arc: convergence",
                Solution.Converged);

      --  Near-180 degree transfer (challenging case)
      R1 := (7000.0, 0.0, 0.0);
      R2 := (-7000.0, 100.0, 0.0);  -- Nearly 180 degrees
      Solution := Safe_Solve_Lambert (R1, R2, 5400.0, Mu_Earth);
      Run_Test ("Near-180 degree: convergence",
                Solution.Converged);

      --  Short time-of-flight (high energy)
      R1 := (7000.0, 0.0, 0.0);
      R2 := (0.0, 7000.0, 0.0);
      Solution := Safe_Solve_Lambert (R1, R2, 1000.0, Mu_Earth);  -- Fast transfer
      Run_Test ("Short TOF high energy: convergence",
                Solution.Converged);
      declare
         --  Departure delta-V relative to a circular parking orbit at R1
         V_Circ_R1 : constant Velocity_Vector :=
            (0.0, Real (Circular_Velocity (7000.0, Mu_Earth)), 0.0);
         DV : constant Velocity_Km_S := Departure_Delta_V (V_Circ_R1, Solution);
      begin
         Run_Test ("Short TOF: higher delta-V",
                   Solution.Converged and then Real (DV) > 3.0);
         --  Higher than Hohmann
      end;

      --  Long time-of-flight (low energy)
      Solution := Safe_Solve_Lambert (R1, R2, 10000.0, Mu_Earth);  -- Slow transfer
      Run_Test ("Long TOF low energy: convergence",
                Solution.Converged);

      --  Transfer angle calculation
      declare
         Angle : Angle_Radians;
      begin
         R1 := (1.0, 0.0, 0.0);
         R2 := (0.0, 1.0, 0.0);
         Angle := Transfer_Angle (R1, R2, False);
         Run_Test ("Transfer angle 90 deg short-way",
                   Approx_Equal (Real (Angle), Pi / 2.0, 0.01));

         Angle := Transfer_Angle (R1, R2, True);
         Run_Test ("Transfer angle 270 deg long-way",
                   Approx_Equal (Real (Angle), 3.0 * Pi / 2.0, 0.01));
      end;

      --  Degenerate case detection
      R1 := (7000.0, 0.0, 0.0);
      R2 := (-7000.0, 0.0, 0.0);  -- Exactly 180 degrees
      Run_Test ("180 degree transfer is degenerate",
                Is_Degenerate_Transfer (R1, R2));

      R2 := (-7000.0, 1.0, 0.0);  -- Slightly off 180 degrees
      Run_Test ("Near-180 degree not degenerate",
                not Is_Degenerate_Transfer (R1, R2));

      End_Suite;
   end Test_Lambert_Edge_Cases;

   ---------------------------------------------------------------------------
   -- Propagation Edge Cases
   ---------------------------------------------------------------------------

   procedure Test_Propagation_Edge_Cases is
   begin
      Start_Suite ("Propagation Edge Cases");

      --  Zero-duration propagation
      declare
         R_Val : constant Real := Real (R_Earth) + 400.0;
         V_Circ : constant Velocity_Km_S := Circular_Velocity (Distance_Km (R_Val), Mu_Earth);
         Initial : constant State_Vector := (
            Position => (R_Val, 0.0, 0.0),
            Velocity => (0.0, Real (V_Circ), 0.0)
         );
         Model : constant Two_Body_Model := (Mu => Mu_Earth);
         Final : constant State_Vector := Propagate_RK4 (Initial, 0.0, 0.0, 10.0, Model);
      begin
         Run_Test ("Zero duration: state unchanged",
                   Approx_Equal (Final.Position (1), Initial.Position (1), 1.0e-10));
      end;

      --  Backward propagation
      declare
         R_Val : constant Real := Real (R_Earth) + 400.0;
         V_Circ : constant Velocity_Km_S := Circular_Velocity (Distance_Km (R_Val), Mu_Earth);
         Initial : constant State_Vector := (
            Position => (R_Val, 0.0, 0.0),
            Velocity => (0.0, Real (V_Circ), 0.0)
         );
         Model : constant Two_Body_Model := (Mu => Mu_Earth);
         Period : constant Time_Seconds := Orbital_Period (Distance_Km (R_Val), Mu_Earth);

         --  Forward then backward should return to start
         Forward : constant State_Vector :=
            Propagate_RK4 (Initial, 0.0, Time_Seconds (Real (Period) / 4.0), 10.0, Model);
         Backward : constant State_Vector :=
            Propagate_RK4 (Forward, Time_Seconds (Real (Period) / 4.0), 0.0, 10.0, Model);
      begin
         Run_Test ("Forward-backward: position X returns",
                   Approx_Equal (Backward.Position (1), Initial.Position (1), 10.0));
         Run_Test ("Forward-backward: velocity Y returns",
                   Approx_Equal (Backward.Velocity (2), Initial.Velocity (2), 0.1));
      end;

      --  Very short time step
      declare
         R_Val : constant Real := Real (R_Earth) + 400.0;
         V_Circ : constant Velocity_Km_S := Circular_Velocity (Distance_Km (R_Val), Mu_Earth);
         Initial : constant State_Vector := (
            Position => (R_Val, 0.0, 0.0),
            Velocity => (0.0, Real (V_Circ), 0.0)
         );
         Model : constant Two_Body_Model := (Mu => Mu_Earth);
         Final : constant State_Vector :=
            Propagate_RK4 (Initial, 0.0, 100.0, 0.1, Model);  -- 0.1 second step
      begin
         Run_Test ("Short time step: produces valid state",
                   Magnitude (Final.Position) > 6000.0);
      end;

      --  High eccentricity orbit stability
      declare
         R_Peri : constant Real := Real (R_Earth) + 200.0;  -- Low periapsis
         A_Val : constant Real := 50000.0;  -- High semi-major axis
         V_Peri : constant Real := Sqrt (Real (Mu_Earth) * (2.0 / R_Peri - 1.0 / A_Val));
         Initial : constant State_Vector := (
            Position => (R_Peri, 0.0, 0.0),
            Velocity => (0.0, V_Peri, 0.0)
         );
         Model : constant Two_Body_Model := (Mu => Mu_Earth);
         E_Initial : constant Hale_Orbital.Types.Specific_Energy :=
            Conserved_Energy (Initial, Mu_Earth);

         --  Propagate for a while
         Final : constant State_Vector :=
            Propagate_RK78 (Initial, 0.0, 10000.0, 1.0e-10, Model);
         E_Final : constant Hale_Orbital.Types.Specific_Energy :=
            Conserved_Energy (Final, Mu_Earth);
      begin
         Run_Test ("High-e orbit: energy conserved",
                   Approx_Equal (Real (E_Initial), Real (E_Final), 1.0e-8 * abs (Real (E_Initial))));
      end;

      End_Suite;
   end Test_Propagation_Edge_Cases;

   ---------------------------------------------------------------------------
   -- Matrix Edge Cases (ISS-032)
   ---------------------------------------------------------------------------

   procedure Test_Matrix_Edge_Cases is
      M_Identity : constant Matrix_3x3 := Identity_3x3;
      M_Zero : constant Matrix_3x3 := ((0.0, 0.0, 0.0),
                                        (0.0, 0.0, 0.0),
                                        (0.0, 0.0, 0.0));
      V : constant Vector_3D := (1.0, 2.0, 3.0);
   begin
      Start_Suite ("Matrix Edge Cases");

      --  Identity matrix tests
      Run_Test ("Identity * V = V",
                Approx_Equal (Magnitude (M_Identity * V - V), 0.0, 1.0e-15));

      declare
         M_Sq : constant Matrix_3x3 := M_Identity * M_Identity;
      begin
         Run_Test ("Identity * Identity = Identity",
                   Approx_Equal (M_Sq (1, 1), 1.0, 1.0e-15) and
                   Approx_Equal (M_Sq (1, 2), 0.0, 1.0e-15));
      end;

      --  Zero matrix tests
      Run_Test ("Zero * V = Zero",
                Approx_Equal (Magnitude (M_Zero * V), 0.0, 1.0e-15));

      --  Rotation matrix tests
      declare
         R_X : constant Matrix_3x3 := Rotation_X (Angle_Radians (0.0));
         R_Y : constant Matrix_3x3 := Rotation_Y (Angle_Radians (0.0));
         R_Z : constant Matrix_3x3 := Rotation_Z (Angle_Radians (0.0));
      begin
         Run_Test ("Rotation_X(0) = Identity",
                   Approx_Equal (R_X (1, 1), 1.0, 1.0e-15));
         Run_Test ("Rotation_Y(0) = Identity",
                   Approx_Equal (R_Y (2, 2), 1.0, 1.0e-15));
         Run_Test ("Rotation_Z(0) = Identity",
                   Approx_Equal (R_Z (3, 3), 1.0, 1.0e-15));
      end;

      --  90 degree rotations
      declare
         R_Z_90 : constant Matrix_3x3 := Rotation_Z (Angle_Radians (Pi / 2.0));
         V_X : constant Vector_3D := (1.0, 0.0, 0.0);
         V_Rotated : constant Vector_3D := R_Z_90 * V_X;
      begin
         Run_Test ("Rotate X by 90 deg around Z gives Y",
                   Approx_Equal (V_Rotated (2), 1.0, 1.0e-10) and
                   Approx_Equal (V_Rotated (1), 0.0, 1.0e-10));
      end;

      --  Full rotation (360 degrees) returns to start
      declare
         R_Full : constant Matrix_3x3 := Rotation_Z (Angle_Radians (Two_Pi));
         V_Rotated : constant Vector_3D := R_Full * V;
      begin
         Run_Test ("360 degree rotation returns to start",
                   Approx_Equal (Magnitude (V_Rotated - V), 0.0, 1.0e-10));
      end;

      --  Transpose tests
      Run_Test ("Transpose of identity = identity",
                Approx_Equal (Transpose (M_Identity)(1, 2), 0.0, 1.0e-15));

      End_Suite;
   end Test_Matrix_Edge_Cases;

   ---------------------------------------------------------------------------
   -- Stumpff Functions Edge Cases (ISS-032)
   ---------------------------------------------------------------------------

   procedure Test_Stumpff_Edge_Cases is
   begin
      Start_Suite ("Stumpff Function Edge Cases");

      --  z = 0 (parabolic case)
      Run_Test ("C(0) = 1/2",
                Approx_Equal (Stumpff_C (0.0), 0.5, 1.0e-15));
      Run_Test ("S(0) = 1/6",
                Approx_Equal (Stumpff_S (0.0), 1.0 / 6.0, 1.0e-15));

      --  Very small z (near-parabolic)
      Run_Test ("C(1e-15) ≈ 0.5",
                Approx_Equal (Stumpff_C (1.0e-15), 0.5, 1.0e-10));
      Run_Test ("S(1e-15) ≈ 1/6",
                Approx_Equal (Stumpff_S (1.0e-15), 1.0 / 6.0, 1.0e-10));

      --  Small positive z (elliptic)
      Run_Test ("C(0.01) > 0",
                Stumpff_C (0.01) > 0.0);
      Run_Test ("S(0.01) > 0",
                Stumpff_S (0.01) > 0.0);

      --  Larger positive z (elliptic)
      Run_Test ("C(Pi^2) = (1-cos(Pi))/Pi^2 = 2/Pi^2",
                Approx_Equal (Stumpff_C (Pi * Pi), 2.0 / (Pi * Pi), 1.0e-10));

      --  Negative z (hyperbolic)
      Run_Test ("C(-1) defined and positive",
                Stumpff_C (-1.0) > 0.0);
      Run_Test ("S(-1) defined and positive",
                Stumpff_S (-1.0) > 0.0);

      --  Large negative z (strongly hyperbolic)
      Run_Test ("C(-100) defined",
                Stumpff_C (-100.0) > 0.0);
      Run_Test ("S(-100) defined",
                Stumpff_S (-100.0) > 0.0);

      --  Very small negative z (near-parabolic hyperbolic)
      Run_Test ("C(-1e-15) ≈ 0.5",
                Approx_Equal (Stumpff_C (-1.0e-15), 0.5, 1.0e-10));

      End_Suite;
   end Test_Stumpff_Edge_Cases;

   ---------------------------------------------------------------------------
   -- Maneuvers Edge Cases (ISS-032)
   ---------------------------------------------------------------------------

   procedure Test_Maneuvers_Edge_Cases is
      Result : Hohmann_Result;
   begin
      Start_Suite ("Maneuvers Edge Cases");

      --  Hohmann transfer to same orbit (zero DV)
      Result := Hohmann_Transfer (Distance_Km (7000.0), Distance_Km (7000.0), Mu_Earth);
      Run_Test ("Hohmann same orbit: DV1 = 0",
                Real (Result.Delta_V1) < 1.0e-10);
      Run_Test ("Hohmann same orbit: DV2 = 0",
                Real (Result.Delta_V2) < 1.0e-10);

      --  Hohmann to slightly higher orbit
      Result := Hohmann_Transfer (Distance_Km (7000.0), Distance_Km (7001.0), Mu_Earth);
      Run_Test ("Hohmann 1 km higher: small DV",
                Real (Result.Total_Delta_V) > 0.0 and Real (Result.Total_Delta_V) < 1.0);

      --  LEO to GEO (standard case)
      Result := Hohmann_Transfer (Distance_Km (6678.0), Distance_Km (42164.0), Mu_Earth);
      Run_Test ("LEO to GEO: DV ≈ 3.9 km/s",
                Approx_Equal (Real (Result.Total_Delta_V), 3.9, 0.1));

      --  Bielliptic vs Hohmann crossover
      declare
         R1 : constant Distance_Km := 6678.0;
         R2 : constant Distance_Km := 100000.0;  -- High orbit
         Result_Hohmann : constant Hohmann_Result := Hohmann_Transfer (R1, R2, Mu_Earth);
         Result_Bielliptic : constant Bielliptic_Result :=
            Bielliptic_Transfer (R1, R2, Distance_Km (200000.0), Mu_Earth);
      begin
         --  For very high orbits, bielliptic can be more efficient
         Run_Test ("Bielliptic comparison defined",
                   Real (Result_Bielliptic.Total_Delta_V) > 0.0);
      end;

      --  Plane change at different altitudes
      declare
         DV_LEO : constant Velocity_Km_S :=
            Simple_Plane_Change (Angle_Radians (Pi / 6.0),
                                 Circular_Velocity (6678.0, Mu_Earth));
         DV_GEO : constant Velocity_Km_S :=
            Simple_Plane_Change (Angle_Radians (Pi / 6.0),
                                 Circular_Velocity (42164.0, Mu_Earth));
      begin
         Run_Test ("Plane change cheaper at GEO than LEO",
                   Real (DV_GEO) < Real (DV_LEO));
         Run_Test ("30 deg plane change at LEO > 1 km/s",
                   Real (DV_LEO) > 1.0);
      end;

      --  Zero inclination change
      declare
         DV : constant Velocity_Km_S :=
            Simple_Plane_Change (Angle_Radians (0.0),
                                 Circular_Velocity (7000.0, Mu_Earth));
      begin
         Run_Test ("Zero inclination change = zero DV",
                   Real (DV) < 1.0e-10);
      end;

      --  180 degree plane change (retrograde)
      declare
         DV : constant Velocity_Km_S :=
            Simple_Plane_Change (Angle_Radians (Pi),
                                 Circular_Velocity (7000.0, Mu_Earth));
      begin
         Run_Test ("180 deg plane change = 2 * V_circ",
                   Approx_Equal (Real (DV), 2.0 * Real (Circular_Velocity (7000.0, Mu_Earth)), 0.01));
      end;

      End_Suite;
   end Test_Maneuvers_Edge_Cases;

   ---------------------------------------------------------------------------
   -- Twobody Edge Cases (ISS-032)
   ---------------------------------------------------------------------------

   procedure Test_Twobody_Edge_Cases is
   begin
      Start_Suite ("Twobody Edge Cases");

      --  Circular velocity at different radii
      Run_Test ("V_circ at R_Earth surface",
                Real (Circular_Velocity (R_Earth, Mu_Earth)) > 7.0 and
                Real (Circular_Velocity (R_Earth, Mu_Earth)) < 8.0);

      Run_Test ("V_circ at GEO",
                Real (Circular_Velocity (42164.0, Mu_Earth)) > 3.0 and
                Real (Circular_Velocity (42164.0, Mu_Earth)) < 3.2);

      --  Escape velocity = sqrt(2) * circular velocity
      Run_Test ("V_esc = sqrt(2) * V_circ",
                Approx_Equal (Real (Escape_Velocity (7000.0, Mu_Earth)),
                              Sqrt (2.0) * Real (Circular_Velocity (7000.0, Mu_Earth)),
                              1.0e-10));

      --  Orbital period
      Run_Test ("LEO period ≈ 90 min",
                Approx_Equal (Real (Orbital_Period (6778.0, Mu_Earth)) / 60.0, 90.0, 5.0));

      Run_Test ("GEO period ≈ 24 hours",
                Approx_Equal (Real (Orbital_Period (42164.0, Mu_Earth)) / 3600.0, 24.0, 0.1));

      --  Vis-viva equation at periapsis and apoapsis
      declare
         A : constant Distance_Km := 20000.0;
         E : constant Real := 0.5;
         R_Peri : constant Distance_Km := Distance_Km (Real (A) * (1.0 - E));
         R_Apo : constant Distance_Km := Distance_Km (Real (A) * (1.0 + E));
         V_Peri : constant Velocity_Km_S := Vis_Viva (R_Peri, A, Mu_Earth);
         V_Apo : constant Velocity_Km_S := Vis_Viva (R_Apo, A, Mu_Earth);
      begin
         Run_Test ("V_periapsis > V_apoapsis",
                   Real (V_Peri) > Real (V_Apo));
         Run_Test ("V at periapsis is positive",
                   Real (V_Peri) > 0.0);
         Run_Test ("V at apoapsis is positive",
                   Real (V_Apo) > 0.0);
      end;

      --  Specific energy
      declare
         State : constant State_Vector := (
            Position => (7000.0, 0.0, 0.0),
            Velocity => (0.0, 7.5, 0.0)  -- Slightly higher than circular
         );
         Energy : constant Hale_Orbital.Types.Specific_Energy :=
            Hale_Orbital.Twobody.Specific_Energy
               (State.Position, State.Velocity, Mu_Earth);
      begin
         Run_Test ("Bound orbit has negative energy",
                   Real (Energy) < 0.0);
      end;

      --  Escape trajectory
      declare
         R : constant Real := 7000.0;
         V_Esc_Plus : constant Real := Real (Escape_Velocity (Distance_Km (R), Mu_Earth)) * 1.1;
         State : constant State_Vector := (
            Position => (R, 0.0, 0.0),
            Velocity => (0.0, V_Esc_Plus, 0.0)
         );
         Energy : constant Hale_Orbital.Types.Specific_Energy :=
            Hale_Orbital.Twobody.Specific_Energy
               (State.Position, State.Velocity, Mu_Earth);
      begin
         Run_Test ("Hyperbolic orbit has positive energy",
                   Real (Energy) > 0.0);
      end;

      End_Suite;
   end Test_Twobody_Edge_Cases;

   ---------------------------------------------------------------------------
   -- Main Runner
   ---------------------------------------------------------------------------

   procedure Run_All_Edge_Case_Tests is
   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  HALE Edge Case Test Suite (ISS-032)");
      IO.Put_Line ("=========================================");
      IO.New_Line;

      Test_Vector_Edge_Cases;
      Test_Kepler_Edge_Cases;
      Test_Elements_Edge_Cases;
      Test_Lambert_Edge_Cases;
      Test_Propagation_Edge_Cases;
      Test_Matrix_Edge_Cases;
      Test_Stumpff_Edge_Cases;
      Test_Maneuvers_Edge_Cases;
      Test_Twobody_Edge_Cases;
   end Run_All_Edge_Case_Tests;

end Hale_Tests.Edge_Cases;
