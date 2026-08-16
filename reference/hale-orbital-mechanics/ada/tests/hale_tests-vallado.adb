-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Vallado Validation Tests Implementation
-------------------------------------------------------------------------------
-- Test cases from Vallado's "Fundamentals of Astrodynamics and Applications"
-- for independent verification of orbital mechanics calculations.
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Tests.Runner; use Hale_Tests.Runner;
with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;   use Hale_Orbital.Vectors;
with Hale_Orbital.Elements;  use Hale_Orbital.Elements;
with Hale_Orbital.Kepler;    use Hale_Orbital.Kepler;
with Hale_Orbital.Maneuvers; use Hale_Orbital.Maneuvers;
with Hale_Orbital.Lambert;   use Hale_Orbital.Lambert;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;

package body Hale_Tests.Vallado is

   package IO renames Ada.Text_IO;
   package Real_Funcs is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Funcs;

   --  Vallado uses slightly different mu value
   Mu_Vallado : constant Gravitational_Parameter := 398600.4418;

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
   -- Vallado Example 2-1: RV to Classical Orbital Elements
   -- Reference: Vallado 4th Edition, Example 2-1, pp. 113-114
   ---------------------------------------------------------------------------

   procedure Test_Vallado_RV_To_COE is
      --  Input state from Vallado Example 2-1
      R : constant Vector_3D := (6524.834, 6862.875, 6448.296);
      V : constant Vector_3D := (4.901327, 5.533756, -1.976341);
      Elements : Orbital_Elements;
   begin
      Start_Suite ("Vallado Example 2-1: RV to COE");

      Elements := State_To_Elements (R, V, Mu_Vallado);

      --  Expected values from Vallado:
      --  p = 11067.790 km (semi-latus rectum)
      --  a = 36127.343 km
      --  e = 0.832853
      --  i = 87.870 deg
      --  RAAN = 227.898 deg
      --  omega = 53.38 deg
      --  nu = 92.335 deg

      Run_Test ("Vallado 2-1: Semi-major axis a = 36127 km",
                Approx_Equal (Real (Elements.Semi_Major_Axis), 36127.343, 10.0));

      Run_Test ("Vallado 2-1: Eccentricity e = 0.8329",
                Approx_Equal (Elements.Eccentricity, 0.832853, 0.001));

      Run_Test ("Vallado 2-1: Inclination i = 87.87 deg",
                Approx_Equal (Real (Elements.Inclination) * Rad_To_Deg, 87.870, 0.01));

      Run_Test ("Vallado 2-1: RAAN = 227.9 deg",
                Approx_Equal (Real (Elements.RAAN) * Rad_To_Deg, 227.898, 0.1));

      Run_Test ("Vallado 2-1: Arg periapsis = 53.38 deg",
                Approx_Equal (Real (Elements.Argument_Of_Periapsis) * Rad_To_Deg, 53.38, 0.1));

      Run_Test ("Vallado 2-1: True anomaly = 92.3 deg",
                Approx_Equal (Real (Elements.True_Anomaly) * Rad_To_Deg, 92.335, 0.5));

      End_Suite;
   end Test_Vallado_RV_To_COE;

   ---------------------------------------------------------------------------
   -- Vallado Example 2-2: COE to RV
   -- Reference: Vallado 4th Edition, Example 2-2, pp. 118-119
   ---------------------------------------------------------------------------

   procedure Test_Vallado_COE_To_RV is
      --  Input elements from Vallado Example 2-2
      Elements : Orbital_Elements;
      State : State_Vector;
   begin
      Start_Suite ("Vallado Example 2-2: COE to RV");

      --  Set up elements (from Vallado)
      --  p = 11067.790 km
      --  e = 0.83285
      --  i = 87.87 deg
      --  RAAN = 227.898 deg
      --  omega = 53.38 deg
      --  nu = 92.335 deg

      --  Compute a from p: p = a(1-e^2) -> a = p/(1-e^2)
      declare
         P_Val : constant Real := 11067.790;
         E_Val : constant Real := 0.83285;
         A_Val : constant Real := P_Val / (1.0 - E_Val ** 2);
      begin
         Elements.Semi_Major_Axis := Distance_Km (A_Val);
      end;
      Elements.Eccentricity := 0.83285;
      Elements.Inclination := Angle_Radians (87.87 * Deg_To_Rad);
      Elements.RAAN := Angle_Radians (227.898 * Deg_To_Rad);
      Elements.Argument_Of_Periapsis := Angle_Radians (53.38 * Deg_To_Rad);
      Elements.True_Anomaly := Angle_Radians (92.335 * Deg_To_Rad);

      State := Elements_To_State (Elements, Mu_Vallado);

      --  Expected values from Vallado:
      --  R = (6525.368, 6861.532, 6449.119) km
      --  V = (4.902279, 5.533140, -1.975710) km/s

      Run_Test ("Vallado 2-2: Position X = 6525 km",
                Approx_Equal (State.Position (1), 6525.368, 10.0));

      Run_Test ("Vallado 2-2: Position Y = 6862 km",
                Approx_Equal (State.Position (2), 6861.532, 10.0));

      Run_Test ("Vallado 2-2: Position Z = 6449 km",
                Approx_Equal (State.Position (3), 6449.119, 10.0));

      Run_Test ("Vallado 2-2: Velocity X = 4.90 km/s",
                Approx_Equal (State.Velocity (1), 4.902279, 0.01));

      Run_Test ("Vallado 2-2: Velocity Y = 5.53 km/s",
                Approx_Equal (State.Velocity (2), 5.533140, 0.01));

      Run_Test ("Vallado 2-2: Velocity Z = -1.98 km/s",
                Approx_Equal (State.Velocity (3), -1.975710, 0.01));

      End_Suite;
   end Test_Vallado_COE_To_RV;

   ---------------------------------------------------------------------------
   -- Vallado Example 2-3: Kepler's Equation
   -- Reference: Vallado 4th Edition, Example 2-3, p. 65
   ---------------------------------------------------------------------------

   procedure Test_Vallado_Kepler is
      M : Angle_Radians;
      E_Anom : Angle_Radians;
      E_Val : Real;
   begin
      Start_Suite ("Vallado Example 2-3: Kepler's Equation");

      --  Vallado Example: e = 0.4, M = 235.4 deg
      M := Angle_Radians (235.4 * Deg_To_Rad);
      E_Val := 0.4;

      E_Anom := Solve_Kepler_Elliptic (M, E_Val);

      --  Expected: E = 220.512 deg (from Vallado)
      Run_Test ("Vallado 2-3: E = 220.5 deg for e=0.4, M=235.4 deg",
                Approx_Equal (Real (E_Anom) * Rad_To_Deg, 220.512, 0.1));

      --  Verify: M = E - e*sin(E)
      declare
         M_Check : constant Real := Real (E_Anom) - E_Val * Sin (Real (E_Anom));
      begin
         Run_Test ("Vallado 2-3: Kepler equation satisfied",
                   Approx_Equal (M_Check, Real (M), 1.0e-10));
      end;

      --  Additional test case from Vallado: e = 0.0001, M = 0.5
      M := Angle_Radians (0.5);
      E_Val := 0.0001;
      E_Anom := Solve_Kepler_Elliptic (M, E_Val);

      Run_Test ("Vallado: Near-circular orbit E ≈ M",
                Approx_Equal (Real (E_Anom), Real (M), 0.001));

      End_Suite;
   end Test_Vallado_Kepler;

   ---------------------------------------------------------------------------
   -- Vallado Example 5-1: Hohmann Transfer
   -- Reference: Vallado 4th Edition, Example 5-1, pp. 326-327
   ---------------------------------------------------------------------------

   procedure Test_Vallado_Hohmann is
      --  Vallado example: Transfer from 191 km circular to 35781 km circular (GEO)
      R1 : constant Distance_Km := Distance_Km (Real (R_Earth) + 191.0);
      R2 : constant Distance_Km := Distance_Km (Real (R_Earth) + 35781.0);
      Result : Hohmann_Result;
   begin
      Start_Suite ("Vallado Example 5-1: Hohmann Transfer");

      Result := Hohmann_Transfer (R1, R2, Mu_Vallado);

      --  Expected from Vallado:
      --  v1 = 7.790 km/s (initial circular)
      --  v_trans1 = 10.252 km/s (transfer periapsis)
      --  Delta-V1 = 2.462 km/s
      --
      --  v_trans2 = 1.597 km/s (transfer apoapsis)
      --  v2 = 3.075 km/s (final circular)
      --  Delta-V2 = 1.478 km/s
      --
      --  Total = 3.940 km/s

      Run_Test ("Vallado 5-1: Delta-V1 = 2.46 km/s",
                Approx_Equal (Real (Result.Delta_V1), 2.462, 0.02));

      Run_Test ("Vallado 5-1: Delta-V2 = 1.48 km/s",
                Approx_Equal (Real (Result.Delta_V2), 1.478, 0.02));

      Run_Test ("Vallado 5-1: Total Delta-V = 3.94 km/s",
                Approx_Equal (Real (Result.Total_Delta_V), 3.940, 0.02));

      --  Transfer orbit properties
      Run_Test ("Vallado 5-1: Transfer SMA = (R1+R2)/2",
                Approx_Equal (Real (Result.A_Transfer),
                              (Real (R1) + Real (R2)) / 2.0, 1.0));

      End_Suite;
   end Test_Vallado_Hohmann;

   ---------------------------------------------------------------------------
   -- Vallado Example 5-5: Simple Plane Change
   -- Reference: Vallado 4th Edition, Example 5-5, p. 340
   ---------------------------------------------------------------------------

   procedure Test_Vallado_Plane_Change is
      --  Vallado: Plane change at v = 7.726 km/s with 30 degree inclination change
      V_Orbit : constant Velocity_Km_S := 7.726;
      Delta_I : constant Angle_Radians := Angle_Radians (30.0 * Deg_To_Rad);
      Delta_V : Velocity_Km_S;
   begin
      Start_Suite ("Vallado Example 5-5: Simple Plane Change");

      Delta_V := Simple_Plane_Change (Delta_I, V_Orbit);

      --  Expected: Delta-V = 2 * v * sin(delta_i/2) = 2 * 7.726 * sin(15 deg)
      --  = 2 * 7.726 * 0.2588 = 3.999 km/s

      Run_Test ("Vallado 5-5: 30 deg plane change DV = 4.0 km/s",
                Approx_Equal (Real (Delta_V), 4.0, 0.05));

      --  Combined plane change at apoapsis (more efficient)
      --  Test 90 degree plane change
      declare
         Delta_I_90 : constant Angle_Radians := Angle_Radians (90.0 * Deg_To_Rad);
         Delta_V_90 : constant Velocity_Km_S := Simple_Plane_Change (Delta_I_90, V_Orbit);
         --  Expected: 2 * 7.726 * sin(45 deg) = 2 * 7.726 * 0.7071 = 10.93 km/s
      begin
         Run_Test ("Vallado: 90 deg plane change DV = 10.93 km/s",
                   Approx_Equal (Real (Delta_V_90), 10.93, 0.1));
      end;

      End_Suite;
   end Test_Vallado_Plane_Change;

   ---------------------------------------------------------------------------
   -- Vallado Example 7-1: Lambert Problem
   -- Reference: Vallado 4th Edition, Example 7-1, p. 467
   ---------------------------------------------------------------------------

   procedure Test_Vallado_Lambert is
      --  Vallado Example 7-1 input:
      --  R1 = (15945.34, 0, 0) km
      --  R2 = (12214.83899, 10249.46731, 0) km
      --  TOF = 76 minutes = 4560 seconds
      R1 : constant Position_Vector := (15945.34, 0.0, 0.0);
      R2 : constant Position_Vector := (12214.83899, 10249.46731, 0.0);
      TOF : constant Time_Seconds := 4560.0;
      Solution : Lambert_Result;
   begin
      Start_Suite ("Vallado Example 7-1: Lambert Problem");

      Solution := Safe_Solve_Lambert (R1, R2, TOF, Mu_Vallado, False);

      --  Expected from Vallado:
      --  V1 = (2.058913, 2.915965, 0) km/s
      --  V2 = (-3.451565, 0.910315, 0) km/s

      Run_Test ("Vallado 7-1: Lambert converged",
                Solution.Converged);

      Run_Test ("Vallado 7-1: V1x = 2.06 km/s",
                Solution.Converged and then
                Approx_Equal (Solution.V1 (1), 2.058913, 0.05));

      Run_Test ("Vallado 7-1: V1y = 2.92 km/s",
                Solution.Converged and then
                Approx_Equal (Solution.V1 (2), 2.915965, 0.05));

      Run_Test ("Vallado 7-1: V1z = 0 km/s",
                Solution.Converged and then
                Approx_Equal (Solution.V1 (3), 0.0, 0.01));

      Run_Test ("Vallado 7-1: V2x = -3.45 km/s",
                Solution.Converged and then
                Approx_Equal (Solution.V2 (1), -3.451565, 0.05));

      Run_Test ("Vallado 7-1: V2y = 0.91 km/s",
                Solution.Converged and then
                Approx_Equal (Solution.V2 (2), 0.910315, 0.05));

      --  Verify transfer angle
      declare
         Angle : constant Angle_Radians := Transfer_Angle (R1, R2, False);
      begin
         --  Expected: ~40 degrees (short-way)
         Run_Test ("Vallado 7-1: Transfer angle ~40 deg",
                   Approx_Equal (Real (Angle) * Rad_To_Deg, 40.0, 5.0));
      end;

      End_Suite;
   end Test_Vallado_Lambert;

   ---------------------------------------------------------------------------
   -- Main Runner
   ---------------------------------------------------------------------------

   procedure Run_All_Vallado_Tests is
   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Vallado Validation Test Suite");
      IO.Put_Line ("  Reference: Vallado (2013) 4th Edition");
      IO.Put_Line ("=========================================");
      IO.New_Line;

      Test_Vallado_RV_To_COE;
      Test_Vallado_COE_To_RV;
      Test_Vallado_Kepler;
      Test_Vallado_Hohmann;
      Test_Vallado_Plane_Change;
      Test_Vallado_Lambert;
   end Run_All_Vallado_Tests;

end Hale_Tests.Vallado;
