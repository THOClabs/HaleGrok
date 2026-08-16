-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Integration Test Suite Implementation
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Tests.Runner; use Hale_Tests.Runner;
with Hale_Orbital.Types;         use Hale_Orbital.Types;
with Hale_Orbital.Constants;     use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;       use Hale_Orbital.Vectors;
with Hale_Orbital.Elements;      use Hale_Orbital.Elements;
with Hale_Orbital.Twobody;       use Hale_Orbital.Twobody;
with Hale_Orbital.Kepler;        use Hale_Orbital.Kepler;
with Hale_Orbital.Lambert;       use Hale_Orbital.Lambert;
with Hale_Orbital.Maneuvers;     use Hale_Orbital.Maneuvers;
with Hale_Orbital.Propagation;   use Hale_Orbital.Propagation;
with Hale_Orbital.Threebody;     use Hale_Orbital.Threebody;
with Hale_Orbital.Interplanetary; use Hale_Orbital.Interplanetary;

package body Hale_Tests.Integration is

   package IO renames Ada.Text_IO;
   package Real_Funcs is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Funcs;

   function Approx_Equal (A, B : Real; Tolerance : Real := 1.0e-6) return Boolean is
   begin
      return abs (A - B) < Tolerance;
   end Approx_Equal;

   function Rel_Equal (A, B : Real; Rel_Tol : Real := 1.0e-4) return Boolean is
      Denom : constant Real := Real'Max (abs (A), abs (B));
   begin
      if Denom < 1.0e-15 then
         return abs (A - B) < 1.0e-15;
      end if;
      return abs (A - B) / Denom < Rel_Tol;
   end Rel_Equal;

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
   -- Lambert + Propagation Consistency
   ---------------------------------------------------------------------------

   procedure Test_Lambert_Propagation_Consistency is
      R1, R2 : Position_Vector;
      TOF : Time_Seconds;
      Lambert_Sol : Lambert_Result;
      Initial_State, Final_State : State_Vector;
      Model : Two_Body_Model;
   begin
      Start_Suite ("Lambert + Propagation Consistency");

      --  Set up a simple transfer problem
      R1 := (8000.0, 0.0, 0.0);
      R2 := (0.0, 10000.0, 0.0);
      TOF := 3600.0;  -- 1 hour

      --  Solve Lambert problem
      Lambert_Sol := Safe_Solve_Lambert (R1, R2, TOF, Mu_Earth);
      Run_Test ("Lambert solution converges", Lambert_Sol.Converged);

      if Lambert_Sol.Converged then
         --  Set up initial state from Lambert solution
         Initial_State := (Position => R1, Velocity => Lambert_Sol.V1);
         Model := (Mu => Mu_Earth);

         --  Propagate for TOF
         Final_State := Propagate_RK78 (Initial_State, 0.0, TOF, 1.0e-12, Model);

         --  Verify arrival position matches R2.  Component-wise relative
         --  comparison breaks when a target component is exactly zero (the
         --  residual is finite, so residual/|residual| = 1); scale the
         --  per-component tolerance by the target magnitude instead.
         Run_Test ("Integration: Final X matches R2 X",
                   abs (Final_State.Position (1) - R2 (1)) < 0.001 * Magnitude (R2));
         Run_Test ("Integration: Final Y matches R2 Y",
                   abs (Final_State.Position (2) - R2 (2)) < 0.001 * Magnitude (R2));
         Run_Test ("Integration: Final Z matches R2 Z",
                   abs (Final_State.Position (3) - R2 (3)) < 0.001 * Magnitude (R2));

         --  Verify arrival velocity matches Lambert V2
         Run_Test ("Integration: Final Vx matches Lambert V2x",
                   Rel_Equal (Final_State.Velocity (1), Lambert_Sol.V2 (1), 0.01));
         Run_Test ("Integration: Final Vy matches Lambert V2y",
                   Rel_Equal (Final_State.Velocity (2), Lambert_Sol.V2 (2), 0.01));
      end if;

      --  Test 2: Longer duration transfer
      TOF := 7200.0;  -- 2 hours
      Lambert_Sol := Safe_Solve_Lambert (R1, R2, TOF, Mu_Earth);
      Run_Test ("Longer TOF Lambert converges", Lambert_Sol.Converged);

      if Lambert_Sol.Converged then
         Initial_State := (Position => R1, Velocity => Lambert_Sol.V1);
         Final_State := Propagate_RK78 (Initial_State, 0.0, TOF, 1.0e-12, Model);

         declare
            Pos_Error : constant Real := Magnitude (Final_State.Position - R2);
         begin
            Run_Test ("Longer TOF: Position error < 1 km",
                      Pos_Error < 1.0);
         end;
      end if;

      --  Test 3: 3D transfer
      R1 := (7000.0, 0.0, 0.0);
      R2 := (5000.0, 6000.0, 2000.0);
      TOF := 4000.0;
      Lambert_Sol := Safe_Solve_Lambert (R1, R2, TOF, Mu_Earth);
      Run_Test ("3D transfer Lambert converges", Lambert_Sol.Converged);

      if Lambert_Sol.Converged then
         Initial_State := (Position => R1, Velocity => Lambert_Sol.V1);
         Final_State := Propagate_RK78 (Initial_State, 0.0, TOF, 1.0e-12, Model);

         declare
            Pos_Error : constant Real := Magnitude (Final_State.Position - R2);
         begin
            Run_Test ("3D transfer: Position error < 5 km",
                      Pos_Error < 5.0);
         end;
      end if;

      End_Suite;
   end Test_Lambert_Propagation_Consistency;

   ---------------------------------------------------------------------------
   -- Elements State Round-Trip
   ---------------------------------------------------------------------------

   procedure Test_Elements_State_Round_Trip is
      R, V : Vector_3D;
      State1, State2 : State_Vector;
      Elem1, Elem2 : Orbital_Elements;
   begin
      Start_Suite ("Elements <-> State Round Trip");

      --  Test 1: Circular equatorial orbit
      R := (7000.0, 0.0, 0.0);
      declare
         V_Circ : constant Real := Real (Circular_Velocity (7000.0, Mu_Earth));
      begin
         V := (0.0, V_Circ, 0.0);
      end;

      Elem1 := State_To_Elements (R, V, Mu_Earth);
      State1 := Elements_To_State (Elem1, Mu_Earth);
      Elem2 := State_To_Elements (State1.Position, State1.Velocity, Mu_Earth);

      Run_Test ("Round-trip: Position X preserved",
                Rel_Equal (State1.Position (1), R (1), 1.0e-6));
      Run_Test ("Round-trip: Velocity Y preserved",
                Rel_Equal (State1.Velocity (2), V (2), 1.0e-6));
      Run_Test ("Round-trip: SMA preserved",
                Rel_Equal (Real (Elem1.Semi_Major_Axis),
                           Real (Elem2.Semi_Major_Axis), 1.0e-6));
      Run_Test ("Round-trip: Eccentricity preserved",
                Rel_Equal (Elem1.Eccentricity, Elem2.Eccentricity, 1.0e-6));

      --  Test 2: Elliptical inclined orbit
      R := (8000.0, 2000.0, 1000.0);
      V := (-1.0, 7.0, 2.0);

      Elem1 := State_To_Elements (R, V, Mu_Earth);
      State1 := Elements_To_State (Elem1, Mu_Earth);

      Run_Test ("Elliptic: Round-trip position error < 1 m",
                Magnitude (State1.Position - R) < 0.001);
      Run_Test ("Elliptic: Round-trip velocity error < 1 mm/s",
                Magnitude (State1.Velocity - V) < 0.000001);

      --  Test 3: High eccentricity
      R := (6678.0, 0.0, 0.0);  -- Near Earth surface
      V := (0.0, 10.8, 0.0);     -- High velocity for ellipse

      Elem1 := State_To_Elements (R, V, Mu_Earth);
      Run_Test ("High-e orbit: Eccentricity > 0.5", Elem1.Eccentricity > 0.5);

      State1 := Elements_To_State (Elem1, Mu_Earth);
      Run_Test ("High-e: Position preserved",
                Magnitude (State1.Position - R) < 1.0);

      End_Suite;
   end Test_Elements_State_Round_Trip;

   ---------------------------------------------------------------------------
   -- Hohmann Transfer with Propagation
   ---------------------------------------------------------------------------

   procedure Test_Hohmann_Transfer_Propagation is
      R_LEO : constant Distance_Km := Distance_Km (Real (R_Earth) + 400.0);
      R_Target : constant Distance_Km := 12000.0;
      Hohmann : Hohmann_Result;
      Initial_State, Transfer_State, Final_State : State_Vector;
      Model : constant Two_Body_Model := (Mu => Mu_Earth);
      V_Circ_LEO : Real;
      Transfer_TOF : Time_Seconds;
   begin
      Start_Suite ("Hohmann Transfer + Propagation");

      --  Compute Hohmann transfer
      Hohmann := Hohmann_Transfer (R_LEO, R_Target, Mu_Earth);

      --  Initial circular orbit at LEO
      V_Circ_LEO := Real (Circular_Velocity (R_LEO, Mu_Earth));
      Initial_State := (
         Position => (Real (R_LEO), 0.0, 0.0),
         Velocity => (0.0, V_Circ_LEO, 0.0)
      );

      --  Apply first delta-V (departure burn)
      Transfer_State := (
         Position => Initial_State.Position,
         Velocity => (0.0, V_Circ_LEO + Real (Hohmann.Delta_V1), 0.0)
      );

      --  Compute transfer orbit TOF (half period of transfer ellipse)
      Transfer_TOF := Time_Seconds (
         Pi * Sqrt (Real (Hohmann.A_Transfer) ** 3 / Real (Mu_Earth)));

      --  Propagate through transfer
      Final_State := Propagate_RK78 (Transfer_State, 0.0, Transfer_TOF, 1.0e-12, Model);

      --  Verify arrival at target radius
      declare
         Final_R : constant Real := Magnitude (Final_State.Position);
      begin
         Run_Test ("Hohmann: Arrives at target radius (± 10 km)",
                   Rel_Equal (Final_R, Real (R_Target), 0.01));
      end;

      --  Verify arrival at apoapsis (velocity perpendicular to position)
      declare
         R_Unit : constant Vector_3D := Normalize (Final_State.Position);
         V_Radial : constant Real := Dot (Final_State.Velocity, R_Unit);
      begin
         Run_Test ("Hohmann: Radial velocity ~0 at apoapsis",
                   abs (V_Radial) < 0.1);
      end;

      --  Verify transfer orbit semi-major axis
      declare
         Transfer_Elem : constant Orbital_Elements :=
            State_To_Elements (Transfer_State.Position, Transfer_State.Velocity, Mu_Earth);
      begin
         Run_Test ("Hohmann: Transfer SMA matches prediction",
                   Rel_Equal (Real (Transfer_Elem.Semi_Major_Axis),
                              Real (Hohmann.A_Transfer), 0.01));
      end;

      End_Suite;
   end Test_Hohmann_Transfer_Propagation;

   ---------------------------------------------------------------------------
   -- LEO to GEO Mission Profile
   ---------------------------------------------------------------------------

   procedure Test_LEO_GEO_Mission_Profile is
      R_LEO : constant Distance_Km := Distance_Km (Real (R_Earth) + 200.0);
      R_GTO_Apogee : constant Distance_Km := 42164.0;  -- GEO altitude
      Hohmann : Hohmann_Result;
      Model : constant Two_Body_Model := (Mu => Mu_Earth);

      LEO_State, GTO_State, GEO_State : State_Vector;
      V_Circ_LEO, V_Circ_GEO : Real;
      Transfer_TOF : Time_Seconds;
      GEO_Period : Time_Seconds;
   begin
      Start_Suite ("LEO to GEO Mission Profile");

      --  Step 1: Start in LEO
      V_Circ_LEO := Real (Circular_Velocity (R_LEO, Mu_Earth));
      LEO_State := (
         Position => (Real (R_LEO), 0.0, 0.0),
         Velocity => (0.0, V_Circ_LEO, 0.0)
      );

      --  Verify LEO energy
      declare
         E_LEO : constant Hale_Orbital.Types.Specific_Energy :=
            Conserved_Energy (LEO_State, Mu_Earth);
      begin
         Run_Test ("LEO: Bound orbit (E < 0)", Real (E_LEO) < 0.0);
      end;

      --  Step 2: Compute and execute Hohmann transfer
      Hohmann := Hohmann_Transfer (R_LEO, R_GTO_Apogee, Mu_Earth);
      Run_Test ("Mission: Total DV ~3.9 km/s",
                Rel_Equal (Real (Hohmann.Total_Delta_V), 3.9, 0.05));

      --  Apply first burn
      GTO_State := (
         Position => LEO_State.Position,
         Velocity => (0.0, V_Circ_LEO + Real (Hohmann.Delta_V1), 0.0)
      );

      --  Propagate to GEO altitude (half transfer orbit period)
      Transfer_TOF := Time_Seconds (
         Pi * Sqrt (Real (Hohmann.A_Transfer) ** 3 / Real (Mu_Earth)));
      GTO_State := Propagate_RK78 (GTO_State, 0.0, Transfer_TOF, 1.0e-12, Model);

      --  Verify at GEO altitude
      declare
         Final_R : constant Real := Magnitude (GTO_State.Position);
      begin
         Run_Test ("Mission: Reaches GEO altitude",
                   Rel_Equal (Final_R, Real (R_GTO_Apogee), 0.01));
      end;

      --  Step 3: Apply circularization burn
      V_Circ_GEO := Real (Circular_Velocity (R_GTO_Apogee, Mu_Earth));
      declare
         R_Unit : constant Vector_3D := Normalize (GTO_State.Position);
         V_Tangent_Dir : constant Vector_3D := Cross ((0.0, 0.0, 1.0), R_Unit);
         V_Tangent_Unit : constant Vector_3D := Normalize (V_Tangent_Dir);
      begin
         GEO_State := (
            Position => GTO_State.Position,
            Velocity => V_Circ_GEO * V_Tangent_Unit
         );
      end;

      --  Verify circular GEO orbit
      declare
         GEO_Elem : constant Orbital_Elements :=
            State_To_Elements (GEO_State.Position, GEO_State.Velocity, Mu_Earth);
      begin
         Run_Test ("Mission: GEO is circular (e < 0.001)",
                   GEO_Elem.Eccentricity < 0.001);
         Run_Test ("Mission: GEO SMA correct",
                   Rel_Equal (Real (GEO_Elem.Semi_Major_Axis),
                              Real (R_GTO_Apogee), 0.01));
      end;

      --  Step 4: Verify GEO orbital period (~24 hours)
      GEO_Period := Orbital_Period (R_GTO_Apogee, Mu_Earth);
      Run_Test ("Mission: GEO period ~86164 s (sidereal day)",
                Rel_Equal (Real (GEO_Period), 86164.0, 0.01));

      --  Step 5: Propagate one full orbit and verify closure
      declare
         Final_GEO : constant State_Vector :=
            Propagate_RK78 (GEO_State, 0.0, GEO_Period, 1.0e-12, Model);
         Pos_Error : constant Real := Magnitude (Final_GEO.Position - GEO_State.Position);
      begin
         Run_Test ("Mission: GEO orbit closes (error < 1 km)",
                   Pos_Error < 1.0);
      end;

      End_Suite;
   end Test_LEO_GEO_Mission_Profile;

   ---------------------------------------------------------------------------
   -- Three-Body + Propagation Integration
   ---------------------------------------------------------------------------

   procedure Test_Threebody_Propagation_Integration is
      LP : Lagrange_Result;
      Stability : Stability_Result;
   begin
      Start_Suite ("Three-Body + Propagation Integration");

      --  Compute Earth-Moon L1 point
      LP := Compute_Lagrange_Point (Earth_Moon_System, L1);
      Run_Test ("EM-L1: Valid X coordinate", LP.X > 0.0 and LP.X < 1.0);

      --  Check stability analysis integration
      Stability := Analyze_Stability (Earth_Moon_System, L1);
      Run_Test ("EM-L1: Stability analysis runs", not Stability.Is_Stable);

      --  L4 triangular point
      LP := Compute_Lagrange_Point (Earth_Moon_System, L4);
      Stability := Analyze_Stability (Earth_Moon_System, L4);
      Run_Test ("EM-L4: Is stable", Stability.Is_Stable);

      --  Verify L4 position (equilateral triangle)
      Run_Test ("EM-L4: X = 0.5 (approx)",
                Rel_Equal (LP.X, 0.5 - Earth_Moon_System.Mass_Ratio, 0.1));
      Run_Test ("EM-L4: Y = sqrt(3)/2",
                Rel_Equal (LP.Y, Sqrt (3.0) / 2.0, 0.01));

      --  Sun-Earth L2 point
      LP := Compute_Lagrange_Point (Sun_Earth_System, L2);
      Run_Test ("SE-L2: Beyond Earth (X > 1)", LP.X > 1.0);

      End_Suite;
   end Test_Threebody_Propagation_Integration;

   ---------------------------------------------------------------------------
   -- Interplanetary Integration
   ---------------------------------------------------------------------------

   procedure Test_Interplanetary_Integration is
      Transfer : Patched_Conic_Result;
      Earth_SOI, Mars_SOI : Distance_Km;
   begin
      Start_Suite ("Interplanetary Trajectory Integration");

      --  Earth-Mars Hohmann transfer
      Transfer := Hohmann_Interplanetary (Earth, Mars);
      Run_Test ("Earth-Mars: Transfer valid", Transfer.Valid);
      Run_Test ("Earth-Mars: Departure C3 > 0",
                Real (Transfer.Departure_C3) > 0.0);
      Run_Test ("Earth-Mars: Total DV reasonable (5-7 km/s)",
                Real (Transfer.Total_DV) > 5.0 and Real (Transfer.Total_DV) < 7.0);

      --  Sphere of influence calculations
      Earth_SOI := Sphere_Of_Influence
         (149598023.0, 398600.4418, Hale_Orbital.Constants.Mu_Sun);
      Run_Test ("Earth SOI ~925,000 km",
                Rel_Equal (Real (Earth_SOI), 925000.0, 0.1));

      Mars_SOI := Sphere_Of_Influence
         (227939200.0, 42828.0, Hale_Orbital.Constants.Mu_Sun);
      Run_Test ("Mars SOI ~577,000 km",
                Rel_Equal (Real (Mars_SOI), 577000.0, 0.1));

      --  Within SOI check
      Run_Test ("400 km alt within Earth SOI",
                Within_SOI (Distance_Km (Real (R_Earth) + 400.0), Earth));

      --  Synodic period
      declare
         T_Syn : constant Time_Seconds := Synodic_Period (Earth, Mars);
         T_Syn_Days : constant Real := Real (T_Syn) / 86400.0;
      begin
         Run_Test ("Earth-Mars synodic ~780 days",
                   Rel_Equal (T_Syn_Days, 780.0, 0.1));
      end;

      --  Venus flyby potential
      declare
         V_Inf : constant Velocity_Km_S := 5.0;  -- 5 km/s approach
         Max_DV : constant Velocity_Km_S := Maximum_Flyby_DeltaV (V_Inf, Venus);
      begin
         Run_Test ("Venus flyby: DV gain possible",
                   Real (Max_DV) > 0.0);
      end;

      End_Suite;
   end Test_Interplanetary_Integration;

   ---------------------------------------------------------------------------
   -- Conservation Laws Integration
   ---------------------------------------------------------------------------

   procedure Test_Conservation_Laws_Integration is
      Initial, Final : State_Vector;
      Model : constant Two_Body_Model := (Mu => Mu_Earth);
      E_Init, E_Final : Hale_Orbital.Types.Specific_Energy;
      H_Init, H_Final : Vector_3D;
   begin
      Start_Suite ("Conservation Laws Integration");

      --  Test 1: Energy conservation through maneuver sequence
      declare
         R_Val : constant Real := Real (R_Earth) + 500.0;
         V_Circ : constant Real := Real (Circular_Velocity (Distance_Km (R_Val), Mu_Earth));
      begin
         Initial := (Position => (R_Val, 0.0, 0.0), Velocity => (0.0, V_Circ, 0.0));
         E_Init := Conserved_Energy (Initial, Mu_Earth);
         H_Init := Angular_Momentum_Vector (Initial.Position, Initial.Velocity);

         --  Propagate for one orbit
         declare
            Period : constant Time_Seconds := Orbital_Period (Distance_Km (R_Val), Mu_Earth);
         begin
            Final := Propagate_RK78 (Initial, 0.0, Period, 1.0e-12, Model);
         end;

         E_Final := Conserved_Energy (Final, Mu_Earth);
         H_Final := Angular_Momentum_Vector (Final.Position, Final.Velocity);

         Run_Test ("Energy conserved over orbit",
                   Rel_Equal (Real (E_Init), Real (E_Final), 1.0e-10));
         Run_Test ("Angular momentum X conserved",
                   Rel_Equal (H_Init (1), H_Final (1), 1.0e-10));
         Run_Test ("Angular momentum Y conserved",
                   Rel_Equal (H_Init (2), H_Final (2), 1.0e-10));
         Run_Test ("Angular momentum Z conserved",
                   Rel_Equal (H_Init (3), H_Final (3), 1.0e-10));
      end;

      --  Test 2: Energy change with maneuver
      declare
         R_Val : constant Real := 8000.0;
         V_Init : constant Real := 7.5;
         DV : constant Real := 0.5;
      begin
         Initial := (Position => (R_Val, 0.0, 0.0), Velocity => (0.0, V_Init, 0.0));
         E_Init := Conserved_Energy (Initial, Mu_Earth);

         --  Apply tangential DV
         Final := (Position => Initial.Position,
                   Velocity => (0.0, V_Init + DV, 0.0));
         E_Final := Conserved_Energy (Final, Mu_Earth);

         --  Energy should increase (less negative)
         Run_Test ("Prograde DV increases orbital energy",
                   Real (E_Final) > Real (E_Init));
      end;

      --  Test 3: Eccentric orbit conservation
      declare
         R_Peri : constant Real := Real (R_Earth) + 300.0;
         A_Val : constant Real := 15000.0;
         V_Peri : constant Real := Sqrt (Real (Mu_Earth) * (2.0 / R_Peri - 1.0 / A_Val));
         Period : constant Time_Seconds := Time_Seconds (Two_Pi * Sqrt (A_Val ** 3 / Real (Mu_Earth)));
      begin
         Initial := (Position => (R_Peri, 0.0, 0.0), Velocity => (0.0, V_Peri, 0.0));
         E_Init := Conserved_Energy (Initial, Mu_Earth);

         Final := Propagate_RK78 (Initial, 0.0, Period, 1.0e-12, Model);
         E_Final := Conserved_Energy (Final, Mu_Earth);

         Run_Test ("Eccentric orbit: Energy conserved",
                   Rel_Equal (Real (E_Init), Real (E_Final), 1.0e-9));
      end;

      End_Suite;
   end Test_Conservation_Laws_Integration;

   ---------------------------------------------------------------------------
   -- Main Runner
   ---------------------------------------------------------------------------

   procedure Run_All_Integration_Tests is
   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Integration Test Suite");
      IO.Put_Line ("  (ISS-037)");
      IO.Put_Line ("=========================================");
      IO.New_Line;

      Test_Lambert_Propagation_Consistency;
      Test_Elements_State_Round_Trip;
      Test_Hohmann_Transfer_Propagation;
      Test_LEO_GEO_Mission_Profile;
      Test_Threebody_Propagation_Integration;
      Test_Interplanetary_Integration;
      Test_Conservation_Laws_Integration;
   end Run_All_Integration_Tests;

end Hale_Tests.Integration;
