-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Lambert Multi-Revolution Tests Implementation
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Tests.Runner; use Hale_Tests.Runner;
with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;   use Hale_Orbital.Vectors;
with Hale_Orbital.Lambert;   use Hale_Orbital.Lambert;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;

package body Hale_Tests.Lambert_MultiRev is

   package IO renames Ada.Text_IO;
   package Real_Funcs is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Funcs;

   --  Helper for approximate equality
   function Approx_Equal (A, B : Real; Tolerance : Real := 1.0e-6) return Boolean is
   begin
      return abs (A - B) < Tolerance;
   end Approx_Equal;

   --  Helper for relative equality
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

   --  Same ISS-010 workaround for the multi-revolution solver: an empty
   --  result array stands for "no solutions", so the length assertions
   --  below fail cleanly instead of aborting the whole test run.
   function Safe_Solve_Lambert_Multi (R1       : Position_Vector;
                                      R2       : Position_Vector;
                                      Tof      : Time_Seconds;
                                      Mu       : Gravitational_Parameter;
                                      Max_Revs : Natural := 0;
                                      Long_Way : Boolean := False)
      return Lambert_Solution_Array is
   begin
      return Solve_Lambert_Multi (R1, R2, Tof, Mu, Max_Revs, Long_Way);
   exception
      when others =>
         declare
            Empty : Lambert_Solution_Array (1 .. 0);
         begin
            return Empty;
         end;
   end Safe_Solve_Lambert_Multi;

   ---------------------------------------------------------------------------
   -- Single-Revolution Tests
   ---------------------------------------------------------------------------

   procedure Test_Single_Rev_Short_Way is
      --  Standard LEO transfer scenarios
      R1, R2 : Position_Vector;
      Result : Lambert_Result;
   begin
      Start_Suite ("Single Revolution - Short Way");

      --  Test 1: 45-degree short-way transfer
      R1 := (7000.0, 0.0, 0.0);
      R2 := (7000.0 * Cos (Pi / 4.0), 7000.0 * Sin (Pi / 4.0), 0.0);
      Result := Safe_Solve_Lambert (R1, R2, 1800.0, Mu_Earth, Long_Way => False);
      Run_Test ("45-deg short-way: converges", Result.Converged);
      Run_Test ("45-deg short-way: positive SMA", Real (Result.A) > 0.0);
      Run_Test ("45-deg short-way: elliptic (e<1)", Result.E < 1.0);

      --  Test 2: 90-degree transfer (quarter orbit)
      R1 := (8000.0, 0.0, 0.0);
      R2 := (0.0, 10000.0, 0.0);
      Result := Safe_Solve_Lambert (R1, R2, 2500.0, Mu_Earth, Long_Way => False);
      Run_Test ("90-deg transfer: converges", Result.Converged);
      Run_Test ("90-deg transfer: valid orbit", Real (Result.A) > 5000.0);

      --  Test 3: 120-degree transfer
      R1 := (7500.0, 0.0, 0.0);
      R2 := (7500.0 * Cos (2.0 * Pi / 3.0), 7500.0 * Sin (2.0 * Pi / 3.0), 0.0);
      Result := Safe_Solve_Lambert (R1, R2, 3000.0, Mu_Earth, Long_Way => False);
      Run_Test ("120-deg transfer: converges", Result.Converged);

      --  Test 4: Fast transfer (high energy)
      R1 := (7000.0, 0.0, 0.0);
      R2 := (0.0, 7000.0, 0.0);
      Result := Safe_Solve_Lambert (R1, R2, 1000.0, Mu_Earth, Long_Way => False);
      Run_Test ("Fast 90-deg: converges", Result.Converged);
      Run_Test ("Fast 90-deg: higher eccentricity", Result.E > 0.1);

      --  Test 5: Slow transfer (low energy).  The original absolute bar
      --  (E < 0.5) was never validated — the correct solution here has
      --  e ~ 0.79, and eccentricity is NOT monotone in TOF (it is minimal
      --  near the minimum-energy transfer and rises on both sides).  The
      --  robust physical invariant is energy: the faster transfer requires
      --  the higher departure speed.
      declare
         Fast_V1 : constant Real := Magnitude (Result.V1);
      begin
         Result := Safe_Solve_Lambert (R1, R2, 6000.0, Mu_Earth, Long_Way => False);
         Run_Test ("Slow 90-deg: converges", Result.Converged);
         Run_Test ("Slow 90-deg: lower departure speed than fast",
                   Magnitude (Result.V1) < Fast_V1);
      end;

      End_Suite;
   end Test_Single_Rev_Short_Way;

   procedure Test_Single_Rev_Long_Way is
      R1, R2 : Position_Vector;
      Result_Short, Result_Long : Lambert_Result;
   begin
      Start_Suite ("Single Revolution - Long Way");

      --  Test 1: 90-degree geometry, long-way = 270-degree transfer
      R1 := (7000.0, 0.0, 0.0);
      R2 := (0.0, 7000.0, 0.0);

      Result_Short := Safe_Solve_Lambert (R1, R2, 3000.0, Mu_Earth, Long_Way => False);
      Result_Long := Safe_Solve_Lambert (R1, R2, 7000.0, Mu_Earth, Long_Way => True);

      Run_Test ("Long-way 270-deg: converges", Result_Long.Converged);
      Run_Test ("Long-way: different SMA than short-way",
                not Approx_Equal (Real (Result_Short.A), Real (Result_Long.A), 100.0));

      --  Test 2: Small angle long-way (nearly 360 degrees)
      R1 := (8000.0, 0.0, 0.0);
      R2 := (8000.0 * Cos (0.2), 8000.0 * Sin (0.2), 0.0);  -- ~11 degree short-way
      Result_Long := Safe_Solve_Lambert (R1, R2, 8000.0, Mu_Earth, Long_Way => True);
      Run_Test ("Near-360-deg long-way: converges", Result_Long.Converged);

      --  Test 3: 60-degree geometry, long-way = 300-degree transfer
      R1 := (7500.0, 0.0, 0.0);
      R2 := (7500.0 * Cos (Pi / 3.0), 7500.0 * Sin (Pi / 3.0), 0.0);
      Result_Long := Safe_Solve_Lambert (R1, R2, 6500.0, Mu_Earth, Long_Way => True);
      Run_Test ("300-deg long-way: converges", Result_Long.Converged);

      End_Suite;
   end Test_Single_Rev_Long_Way;

   ---------------------------------------------------------------------------
   -- Multi-Revolution Fundamental Tests
   ---------------------------------------------------------------------------

   procedure Test_Multi_Rev_Min_TOF is
      R1, R2 : Position_Vector;
      Min_T0, Min_T1, Min_T2, Min_T3 : Time_Seconds;
   begin
      Start_Suite ("Multi-Rev Minimum TOF Calculations");

      --  Standard test geometry
      R1 := (10000.0, 0.0, 0.0);
      R2 := (0.0, 15000.0, 0.0);

      --  Get minimum TOF for 0, 1, 2, 3 revolutions
      Min_T0 := Min_Tof_N_Revs (R1, R2, Mu_Earth, 0, False);
      Min_T1 := Min_Tof_N_Revs (R1, R2, Mu_Earth, 1, False);
      Min_T2 := Min_Tof_N_Revs (R1, R2, Mu_Earth, 2, False);
      Min_T3 := Min_Tof_N_Revs (R1, R2, Mu_Earth, 3, False);

      --  Minimum TOF should increase with revolution count
      Run_Test ("Min TOF(0) > 0", Real (Min_T0) > 0.0);
      Run_Test ("Min TOF(1) > Min TOF(0)", Real (Min_T1) > Real (Min_T0));
      Run_Test ("Min TOF(2) > Min TOF(1)", Real (Min_T2) > Real (Min_T1));
      Run_Test ("Min TOF(3) > Min TOF(2)", Real (Min_T3) > Real (Min_T2));

      --  The increment between revolutions should be roughly one orbital period
      declare
         Delta_01 : constant Real := Real (Min_T1) - Real (Min_T0);
         Delta_12 : constant Real := Real (Min_T2) - Real (Min_T1);
         Delta_23 : constant Real := Real (Min_T3) - Real (Min_T2);
      begin
         Run_Test ("Delta TOF 0->1 reasonable", Delta_01 > 1000.0);
         Run_Test ("Delta TOF consistent", Rel_Equal (Delta_12, Delta_23, 0.3));
      end;

      --  Different geometry test
      R1 := (7000.0, 0.0, 0.0);
      R2 := (-7000.0, 1000.0, 0.0);  -- Near 180-degree
      Min_T0 := Min_Tof_N_Revs (R1, R2, Mu_Earth, 0, False);
      Min_T1 := Min_Tof_N_Revs (R1, R2, Mu_Earth, 1, False);
      Run_Test ("Near-180: Min TOF(0) valid", Real (Min_T0) > 0.0);
      Run_Test ("Near-180: Min TOF(1) > TOF(0)", Real (Min_T1) > Real (Min_T0));

      End_Suite;
   end Test_Multi_Rev_Min_TOF;

   procedure Test_Multi_Rev_Solution_Counting is
      R1, R2 : Position_Vector;
      Count : Natural;
      Min_T1 : Time_Seconds;
   begin
      Start_Suite ("Multi-Rev Solution Counting");

      R1 := (10000.0, 0.0, 0.0);
      R2 := (0.0, 12000.0, 0.0);

      --  Short TOF: only zero-revolution solution
      Min_T1 := Min_Tof_N_Revs (R1, R2, Mu_Earth, 1, False);

      --  TOF less than 1-rev minimum: should have 1 solution
      Count := Count_Multi_Rev_Solutions (R1, R2,
                                          Time_Seconds (Real (Min_T1) * 0.8),
                                          Mu_Earth, Max_Revs => 3);
      Run_Test ("Short TOF: 1 solution (0-rev only)", Count = 1);

      --  TOF just above 1-rev minimum: should have 3 solutions (0-rev + 2×1-rev)
      Count := Count_Multi_Rev_Solutions (R1, R2,
                                          Time_Seconds (Real (Min_T1) * 1.2),
                                          Mu_Earth, Max_Revs => 3);
      Run_Test ("Above 1-rev min: 3 solutions", Count = 3);

      --  Long TOF: multiple revolution solutions possible
      declare
         Min_T2 : constant Time_Seconds := Min_Tof_N_Revs (R1, R2, Mu_Earth, 2, False);
      begin
         Count := Count_Multi_Rev_Solutions (R1, R2,
                                             Time_Seconds (Real (Min_T2) * 1.2),
                                             Mu_Earth, Max_Revs => 3);
         Run_Test ("Above 2-rev min: 5 solutions", Count = 5);
      end;

      --  Degenerate case: 180-degree transfer
      R1 := (7000.0, 0.0, 0.0);
      R2 := (-7000.0, 0.0, 0.0);
      Count := Count_Multi_Rev_Solutions (R1, R2, 5000.0, Mu_Earth, Max_Revs => 3);
      Run_Test ("180-deg degenerate: 0 solutions", Count = 0);

      End_Suite;
   end Test_Multi_Rev_Solution_Counting;

   ---------------------------------------------------------------------------
   -- N-Revolution Transfer Tests
   ---------------------------------------------------------------------------

   procedure Test_One_Revolution_Transfer is
      R1, R2 : Position_Vector;
      Min_T1 : Time_Seconds;
      TOF : Time_Seconds;
   begin
      Start_Suite ("One Revolution Transfer");

      R1 := (8000.0, 0.0, 0.0);
      R2 := (0.0, 10000.0, 0.0);

      --  Get minimum TOF for 1 revolution
      Min_T1 := Min_Tof_N_Revs (R1, R2, Mu_Earth, 1, False);

      --  Test at 1.5x minimum TOF (well above threshold)
      TOF := Time_Seconds (Real (Min_T1) * 1.5);

      declare
         Solutions : constant Lambert_Solution_Array :=
            Safe_Solve_Lambert_Multi (R1, R2, TOF, Mu_Earth, Max_Revs => 1);
      begin
         Run_Test ("1-rev: multiple solutions returned", Solutions'Length >= 2);

         --  Check that we have valid solutions
         if Solutions'Length >= 1 then
            Run_Test ("1-rev: first solution converged", Solutions (0).Converged);
            Run_Test ("1-rev: first solution valid SMA", Real (Solutions (0).A) > 0.0);
         end if;

         if Solutions'Length >= 2 then
            Run_Test ("1-rev: second solution converged", Solutions (1).Converged);
         end if;

         --  Test that short and long period solutions have different energies
         if Solutions'Length >= 3 then
            --  Solutions 1 and 2 are the 1-rev short and long period
            Run_Test ("1-rev: short/long have different SMA",
                      not Approx_Equal (Real (Solutions (1).A),
                                        Real (Solutions (2).A), 100.0));
         end if;
      end;

      End_Suite;
   end Test_One_Revolution_Transfer;

   procedure Test_Two_Revolution_Transfer is
      R1, R2 : Position_Vector;
      Min_T2 : Time_Seconds;
      TOF : Time_Seconds;
   begin
      Start_Suite ("Two Revolution Transfer");

      R1 := (9000.0, 0.0, 0.0);
      R2 := (0.0, 11000.0, 0.0);

      --  Get minimum TOF for 2 revolutions
      Min_T2 := Min_Tof_N_Revs (R1, R2, Mu_Earth, 2, False);

      --  Test at 1.3x minimum TOF
      TOF := Time_Seconds (Real (Min_T2) * 1.3);

      declare
         Solutions : constant Lambert_Solution_Array :=
            Safe_Solve_Lambert_Multi (R1, R2, TOF, Mu_Earth, Max_Revs => 2);
      begin
         --  Should have: 1 zero-rev + 2 one-rev + 2 two-rev = 5 solutions
         Run_Test ("2-rev: multiple solutions (expect ~5)", Solutions'Length >= 3);

         --  All returned solutions should be converged
         for I in Solutions'Range loop
            Run_Test ("2-rev solution " & Natural'Image (I) & " converged",
                      Solutions (I).Converged);
         end loop;

         --  Check solution variety
         if Solutions'Length >= 2 then
            declare
               SMA_Min : Real := Real (Solutions (Solutions'First).A);
               SMA_Max : Real := Real (Solutions (Solutions'First).A);
            begin
               for I in Solutions'Range loop
                  if Real (Solutions (I).A) < SMA_Min then
                     SMA_Min := Real (Solutions (I).A);
                  end if;
                  if Real (Solutions (I).A) > SMA_Max then
                     SMA_Max := Real (Solutions (I).A);
                  end if;
               end loop;
               Run_Test ("2-rev: solutions span SMA range", SMA_Max > SMA_Min * 1.1);
            end;
         end if;
      end;

      End_Suite;
   end Test_Two_Revolution_Transfer;

   procedure Test_Three_Revolution_Transfer is
      R1, R2 : Position_Vector;
      Min_T3 : Time_Seconds;
      TOF : Time_Seconds;
   begin
      Start_Suite ("Three Revolution Transfer");

      R1 := (10000.0, 0.0, 0.0);
      R2 := (0.0, 12000.0, 0.0);

      --  Get minimum TOF for 3 revolutions
      Min_T3 := Min_Tof_N_Revs (R1, R2, Mu_Earth, 3, False);

      --  Test at 1.2x minimum TOF
      TOF := Time_Seconds (Real (Min_T3) * 1.2);

      declare
         Solutions : constant Lambert_Solution_Array :=
            Safe_Solve_Lambert_Multi (R1, R2, TOF, Mu_Earth, Max_Revs => 3);
      begin
         --  Should have up to 7 solutions (1 + 2 + 2 + 2)
         Run_Test ("3-rev: returns multiple solutions", Solutions'Length >= 1);

         --  Verify all solutions are valid elliptic orbits
         for I in Solutions'Range loop
            if Solutions (I).Converged then
               Run_Test ("3-rev sol " & Natural'Image (I) & ": elliptic",
                         Solutions (I).E < 1.0 and Solutions (I).E >= 0.0);
            end if;
         end loop;
      end;

      End_Suite;
   end Test_Three_Revolution_Transfer;

   ---------------------------------------------------------------------------
   -- Edge Cases and Boundaries
   ---------------------------------------------------------------------------

   procedure Test_Revolution_Boundary_Cases is
      R1, R2 : Position_Vector;
      Min_T1 : Time_Seconds;
      Result : Lambert_Result;
      Count : Natural;
   begin
      Start_Suite ("Revolution Boundary Cases");

      R1 := (8000.0, 0.0, 0.0);
      R2 := (0.0, 9000.0, 0.0);

      Min_T1 := Min_Tof_N_Revs (R1, R2, Mu_Earth, 1, False);

      --  Test exactly at 1-rev minimum (boundary case)
      Count := Count_Multi_Rev_Solutions (R1, R2, Min_T1, Mu_Earth, Max_Revs => 2);
      --  At exact minimum, 1-rev solutions should exist but may be degenerate
      Run_Test ("At 1-rev minimum: solutions exist", Count >= 1);

      --  Test just below 1-rev minimum
      Count := Count_Multi_Rev_Solutions (R1, R2,
                                          Time_Seconds (Real (Min_T1) * 0.99),
                                          Mu_Earth, Max_Revs => 2);
      Run_Test ("Below 1-rev minimum: only 0-rev solution", Count = 1);

      --  Test just above 1-rev minimum
      Count := Count_Multi_Rev_Solutions (R1, R2,
                                          Time_Seconds (Real (Min_T1) * 1.01),
                                          Mu_Earth, Max_Revs => 2);
      Run_Test ("Above 1-rev minimum: 1-rev solutions appear", Count >= 3);

      --  Test very close to 180-degree (near-degenerate)
      R1 := (7000.0, 0.0, 0.0);
      R2 := (-7000.0, 10.0, 0.0);  -- Very small offset
      Run_Test ("Near-180: not degenerate", not Is_Degenerate_Transfer (R1, R2));

      Result := Safe_Solve_Lambert (R1, R2, 5400.0, Mu_Earth);
      Run_Test ("Near-180: solver converges", Result.Converged);

      End_Suite;
   end Test_Revolution_Boundary_Cases;

   procedure Test_Energy_Branch_Selection is
      R1, R2 : Position_Vector;
      Result_Low_E, Result_High_E : Lambert_Result;
      TOF_Short, TOF_Long : Time_Seconds;
   begin
      Start_Suite ("Energy Branch Selection");

      R1 := (7000.0, 0.0, 0.0);
      R2 := (0.0, 8000.0, 0.0);

      --  Short TOF = high energy, Long TOF = low energy
      TOF_Short := 1500.0;
      TOF_Long := 4000.0;

      Result_High_E := Safe_Solve_Lambert (R1, R2, TOF_Short, Mu_Earth);
      Result_Low_E := Safe_Solve_Lambert (R1, R2, TOF_Long, Mu_Earth);

      Run_Test ("High energy (short TOF): converges", Result_High_E.Converged);
      Run_Test ("Low energy (long TOF): converges", Result_Low_E.Converged);

      --  High energy orbit should have smaller SMA (more bound)
      --  Actually, shorter TOF often means higher energy which could be either
      --  higher or lower SMA depending on geometry
      Run_Test ("Different TOF -> different orbits",
                not Approx_Equal (Real (Result_High_E.A),
                                  Real (Result_Low_E.A), 100.0));

      --  Verify velocity magnitudes differ
      declare
         V1_High : constant Real := Magnitude (Result_High_E.V1);
         V1_Low : constant Real := Magnitude (Result_Low_E.V1);
      begin
         --  Correct solutions differ by ~6% here; the original 10% bar was
         --  never validated.  1% still asserts a physically meaningful gap.
         Run_Test ("Departure velocity differs", not Rel_Equal (V1_High, V1_Low, 0.01));
      end;

      End_Suite;
   end Test_Energy_Branch_Selection;

   ---------------------------------------------------------------------------
   -- Published Results Validation
   ---------------------------------------------------------------------------

   procedure Test_Published_Multi_Rev_Cases is
      R1, R2 : Position_Vector;
      Result : Lambert_Result;
   begin
      Start_Suite ("Published Multi-Rev Cases");

      --  Case 1: Curtis Example (Orbital Mechanics for Engineering Students)
      --  Earth departure to Mars arrival
      --  R1 = 1 AU, R2 = 1.524 AU, TOF = 207 days (Type I Hohmann-like)
      --  Using scaled Earth-centered test
      R1 := (15000.0, 0.0, 0.0);
      R2 := (0.0, 20000.0, 5000.0);  -- 3D transfer
      Result := Safe_Solve_Lambert (R1, R2, 15000.0, Mu_Earth);
      Run_Test ("3D transfer: converges", Result.Converged);
      Run_Test ("3D transfer: valid orbit", Real (Result.A) > 10000.0);

      --  Case 2: Battin Example
      --  Testing algorithm robustness with different geometries
      R1 := (5000.0, 10000.0, 2100.0);
      R2 := (-14600.0, 2500.0, 7000.0);
      Result := Safe_Solve_Lambert (R1, R2, 3600.0, Mu_Earth);
      Run_Test ("Battin-style 3D: converges", Result.Converged);

      --  Case 3: Multi-rev validation
      R1 := (10000.0, 0.0, 0.0);
      R2 := (0.0, 15000.0, 0.0);
      --  Long TOF to allow multiple revolutions
      declare
         Solutions : constant Lambert_Solution_Array :=
            Safe_Solve_Lambert_Multi (R1, R2, 50000.0, Mu_Earth, Max_Revs => 2);
      begin
         Run_Test ("Long TOF multi-rev: returns solutions", Solutions'Length >= 1);

         --  All returned solutions should produce valid transfers
         for I in Solutions'Range loop
            if Solutions (I).Converged then
               --  Basic sanity: SMA should be positive for elliptic
               Run_Test ("Multi-rev sol " & Natural'Image (I) & ": SMA > 0",
                         Real (Solutions (I).A) > 0.0);
            end if;
         end loop;
      end;

      --  Case 4: Vallado-style test with known result
      --  From Vallado Example 7-1 extended
      R1 := (15945.34, 0.0, 0.0);
      R2 := (12214.83899, 10249.46731, 0.0);
      Result := Safe_Solve_Lambert (R1, R2, 4560.0, Mu_Earth);
      Run_Test ("Vallado 7-1: converges", Result.Converged);
      --  Expected V1 ≈ (2.06, 2.92, 0) km/s
      Run_Test ("Vallado 7-1: V1x reasonable",
                Approx_Equal (Result.V1 (1), 2.06, 0.1));
      Run_Test ("Vallado 7-1: V1y reasonable",
                Approx_Equal (Result.V1 (2), 2.92, 0.1));

      End_Suite;
   end Test_Published_Multi_Rev_Cases;

   ---------------------------------------------------------------------------
   -- Constructive Two-Revolution Recovery (adversarial reproducer)
   ---------------------------------------------------------------------------
   --  Geometry with a KNOWN 2-rev solution: points at nu = 0.4 and 2.1 rad
   --  on the ellipse a = 12000 km, e = 0.3 (planar prograde), requested
   --  TOF = single-arc TOF + 2 orbital periods.  The generating orbit
   --  itself is then a 2-revolution Lambert solution with
   --  v1 = (-2.35274, 7.37726, 0) km/s.  The pre-fix enumeration used
   --  wrong z-windows (((2N-1)**2*pi**2, (2N+1)**2*pi**2) split at
   --  4*N**2*pi**2) and increasing-only bisection, so it returned the
   --  zero-rev root twice and missed this solution entirely.

   procedure Test_Constructive_Two_Rev is
      A_Gen : constant Real := 12000.0;
      E_Gen : constant Real := 0.3;
      P_Gen : constant Real := A_Gen * (1.0 - E_Gen**2);
      Nu1   : constant Real := 0.4;
      Nu2   : constant Real := 2.1;

      function Ecc_Anom (Nu : Real) return Real is
         (Arctan (Sqrt (1.0 - E_Gen**2) * Sin (Nu), E_Gen + Cos (Nu)));

      M1 : constant Real := Ecc_Anom (Nu1) - E_Gen * Sin (Ecc_Anom (Nu1));
      M2 : constant Real := Ecc_Anom (Nu2) - E_Gen * Sin (Ecc_Anom (Nu2));

      Sqrt_A3_Mu : constant Real := Sqrt (A_Gen**3 / Real (Mu_Earth));
      Period : constant Real := Two_Pi * Sqrt_A3_Mu;
      TOF    : constant Real := Sqrt_A3_Mu * (M2 - M1) + 2.0 * Period;

      function Pos_At (Nu : Real) return Position_Vector is
         R_Mag : constant Real := P_Gen / (1.0 + E_Gen * Cos (Nu));
      begin
         return (R_Mag * Cos (Nu), R_Mag * Sin (Nu), 0.0);
      end Pos_At;

      R1 : constant Position_Vector := Pos_At (Nu1);
      R2 : constant Position_Vector := Pos_At (Nu2);

      --  Departure velocity of the generating orbit at nu = 0.4
      V1_Gen : constant Velocity_Vector :=
         (-Sqrt (Real (Mu_Earth) / P_Gen) * Sin (Nu1),
          Sqrt (Real (Mu_Earth) / P_Gen) * (E_Gen + Cos (Nu1)),
          0.0);

      Solutions : constant Lambert_Solution_Array :=
         Safe_Solve_Lambert_Multi (R1, R2, Time_Seconds (TOF), Mu_Earth,
                                   Max_Revs => 3);

      Found_Generating : Boolean := False;
      All_Distinct     : Boolean := True;
   begin
      Start_Suite ("Constructive 2-Rev Recovery");

      for I in Solutions'Range loop
         if abs (Solutions (I).V1 (1) - V1_Gen (1)) < 1.0e-4
            and then abs (Solutions (I).V1 (2) - V1_Gen (2)) < 1.0e-4
            and then abs (Solutions (I).V1 (3) - V1_Gen (3)) < 1.0e-4
         then
            Found_Generating := True;
         end if;
         for J in I + 1 .. Solutions'Last loop
            if Magnitude (Solutions (I).V1 - Solutions (J).V1) <= 1.0e-6 then
               All_Distinct := False;
            end if;
         end loop;
      end loop;

      Run_Test ("2-rev: solutions returned for TOF = arc + 2 periods",
                Solutions'Length >= 5);
      Run_Test ("2-rev: known generating orbit recovered (v1 to 1e-4 km/s)",
                Found_Generating);
      Run_Test ("2-rev: no duplicate solutions (pairwise v1 differ)",
                All_Distinct);
      Run_Test ("2-rev: Count_Multi_Rev_Solutions equals returned length",
                Count_Multi_Rev_Solutions (R1, R2, Time_Seconds (TOF),
                                           Mu_Earth, Max_Revs => 3)
                = Solutions'Length);

      End_Suite;
   end Test_Constructive_Two_Rev;

   ---------------------------------------------------------------------------
   -- Parabolic TOF Bound (Solution_Exists / Minimum_Energy_Tof)
   ---------------------------------------------------------------------------
   --  The parabolic minimum TOF is (1/3)*sqrt(2/mu)*(s**1.5 - sign*(s-c)**1.5)
   --  with sign +1 short-way / -1 long-way.  The pre-fix code dropped the
   --  (s-c)**1.5 term, overstating the short-way bound (2337.3 s instead of
   --  1534.9 s for Vallado 7-1 geometry), so Solution_Exists rejected
   --  solvable transfers such as TOF = 1936 s.

   procedure Test_Parabolic_Bound is
      R1 : constant Position_Vector := (15945.34, 0.0, 0.0);
      R2 : constant Position_Vector := (12214.83899, 10249.46731, 0.0);
   begin
      Start_Suite ("Parabolic TOF Bound (Vallado 7-1 geometry)");

      Run_Test ("Solution_Exists TRUE at TOF = 1936 s (solvable elliptic)",
                Solution_Exists (R1, R2, 1936.0, Mu_Earth));
      Run_Test ("Short-way parabolic TOF ~ 1534.9 s",
                Approx_Equal (Real (Minimum_Energy_Tof (R1, R2, Mu_Earth,
                                                        Long_Way => False)),
                              1534.9, 0.5));
      Run_Test ("Long-way bound exceeds short-way bound",
                Real (Minimum_Energy_Tof (R1, R2, Mu_Earth, Long_Way => True))
                > Real (Minimum_Energy_Tof (R1, R2, Mu_Earth,
                                            Long_Way => False)));

      declare
         Result : constant Lambert_Result :=
            Safe_Solve_Lambert (R1, R2, 1936.0, Mu_Earth);
      begin
         Run_Test ("Solver converges at TOF = 1936 s", Result.Converged);
      end;

      --  Below the true parabolic bound the transfer is hyperbolic
      Run_Test ("Solution_Exists FALSE below parabolic bound",
                not Solution_Exists (R1, R2, 1400.0, Mu_Earth));

      End_Suite;
   end Test_Parabolic_Bound;

   ---------------------------------------------------------------------------
   -- Main Runner
   ---------------------------------------------------------------------------

   procedure Run_All_Lambert_MultiRev_Tests is
   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Lambert Multi-Revolution Test Suite");
      IO.Put_Line ("  (ISS-030)");
      IO.Put_Line ("=========================================");
      IO.New_Line;

      Test_Single_Rev_Short_Way;
      Test_Single_Rev_Long_Way;
      Test_Multi_Rev_Min_TOF;
      Test_Multi_Rev_Solution_Counting;
      Test_One_Revolution_Transfer;
      Test_Two_Revolution_Transfer;
      Test_Three_Revolution_Transfer;
      Test_Revolution_Boundary_Cases;
      Test_Energy_Branch_Selection;
      Test_Published_Multi_Rev_Cases;
      Test_Constructive_Two_Rev;
      Test_Parabolic_Bound;
   end Run_All_Lambert_MultiRev_Tests;

end Hale_Tests.Lambert_MultiRev;
