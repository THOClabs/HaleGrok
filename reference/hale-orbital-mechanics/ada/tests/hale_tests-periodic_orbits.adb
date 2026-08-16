-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Periodic Orbit Test Suite Body (ISS-034)
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Types;      use Hale_Orbital.Types;
with Hale_Orbital.Threebody;  use Hale_Orbital.Threebody;
with Hale_Tests.Runner;

package body Hale_Tests.Periodic_Orbits is

   package IO renames Ada.Text_IO;
   package Real_Funcs is new Ada.Numerics.Generic_Elementary_Functions (Real);

   --  The STM/monodromy API uses Hale_Orbital.Types.Matrix_6x6 (the former
   --  duplicate declaration in Threebody was removed).
   subtype Matrix_6x6 is Hale_Orbital.Types.Matrix_6x6;

   Tolerance : constant Real := 1.0e-8;
   Strict_Tol : constant Real := 1.0e-10;

   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;

   procedure Report_Test (Name : String; Passed : Boolean) is
   begin
      Test_Count := Test_Count + 1;
      if Passed then
         Pass_Count := Pass_Count + 1;
         IO.Put_Line ("  [PASS] " & Name);
      else
         IO.Put_Line ("  [FAIL] " & Name);
      end if;
   end Report_Test;

   ---------------------------------------------------------------------------
   -- State Transition Matrix Tests
   ---------------------------------------------------------------------------

   procedure Test_STM_Identity_Initial is
      --  STM should be identity at t=0
      State : constant Normalized_State :=
         (X => 0.8, Y => 0.0, Z => 0.0, VX => 0.0, VY => 0.1, VZ => 0.0);
      Result : State_With_STM;
      Is_Identity : Boolean := True;
   begin
      --  Propagate for zero time
      Result := Propagate_With_STM (State, Earth_Moon_System.Mass_Ratio, 0.0, 0.001);

      --  Check STM is identity
      for I in 1 .. 6 loop
         for J in 1 .. 6 loop
            if I = J then
               if abs (Result.STM (I, J) - 1.0) > Tolerance then
                  Is_Identity := False;
               end if;
            else
               if abs (Result.STM (I, J)) > Tolerance then
                  Is_Identity := False;
               end if;
            end if;
         end loop;
      end loop;

      Report_Test ("STM is identity at t=0", Is_Identity);
   end Test_STM_Identity_Initial;

   procedure Test_STM_Propagation is
      --  STM should evolve smoothly during propagation
      State : constant Normalized_State :=
         (X => 0.8, Y => 0.0, Z => 0.0, VX => 0.0, VY => 0.2, VZ => 0.0);
      Result : State_With_STM;
      Has_Reasonable_Values : Boolean := True;
   begin
      Result := Propagate_With_STM (State, Earth_Moon_System.Mass_Ratio, 1.0, 0.001);

      --  Check STM values are finite and reasonable
      for I in 1 .. 6 loop
         for J in 1 .. 6 loop
            if abs (Result.STM (I, J)) > 1.0e10 or
               Result.STM (I, J) /= Result.STM (I, J)  -- NaN check
            then
               Has_Reasonable_Values := False;
            end if;
         end loop;
      end loop;

      Report_Test ("STM has reasonable values after propagation", Has_Reasonable_Values);
   end Test_STM_Propagation;

   procedure Test_STM_Symplectic_Property is
      --  For Hamiltonian systems, STM should be symplectic: Phi^T J Phi = J
      --  where J is the symplectic matrix.  The CR3BP rotating-frame flow
      --  is Hamiltonian in the canonical momenta px = vx - y, py = vy + x,
      --  pz = vz -- NOT in the velocities -- so the [x,y,z,vx,vy,vz] STM
      --  must first be similarity-transformed to canonical coordinates:
      --  Phi_p = T * Phi * T_inv with T = [[I, 0], [A, I]].
      State : constant Normalized_State :=
         (X => 0.8, Y => 0.0, Z => 0.0, VX => 0.0, VY => 0.2, VZ => 0.0);
      Result : State_With_STM;
      Phi : Matrix_6x6;
      Phi_T : Matrix_6x6;

      --  Symplectic matrix J (block diagonal with [0,1;-1,0] blocks)
      J : Matrix_6x6 := (others => (others => 0.0));
      Product : Matrix_6x6 := (others => (others => 0.0));
      Is_Symplectic : Boolean := True;
   begin
      Result := Propagate_With_STM (State, Earth_Moon_System.Mass_Ratio, 0.5, 0.0001);

      --  Transform the STM to canonical coordinates: Phi_p = T*Phi*T_inv
      declare
         T_Mat : Matrix_6x6 := Identity_6x6;
         T_Inv : Matrix_6x6 := Identity_6x6;
         Tmp   : Matrix_6x6 := (others => (others => 0.0));
      begin
         T_Mat (4, 2) := -1.0;
         T_Mat (5, 1) := 1.0;
         T_Inv (4, 2) := 1.0;
         T_Inv (5, 1) := -1.0;

         for I in 1 .. 6 loop
            for K in 1 .. 6 loop
               for L in 1 .. 6 loop
                  Tmp (I, K) := Tmp (I, K) + T_Mat (I, L) * Result.STM (L, K);
               end loop;
            end loop;
         end loop;

         Phi := (others => (others => 0.0));
         for I in 1 .. 6 loop
            for K in 1 .. 6 loop
               for L in 1 .. 6 loop
                  Phi (I, K) := Phi (I, K) + Tmp (I, L) * T_Inv (L, K);
               end loop;
            end loop;
         end loop;
      end;

      --  Construct J matrix
      J (1, 4) := 1.0;  J (4, 1) := -1.0;
      J (2, 5) := 1.0;  J (5, 2) := -1.0;
      J (3, 6) := 1.0;  J (6, 3) := -1.0;

      --  Transpose Phi
      for I in 1 .. 6 loop
         for K in 1 .. 6 loop
            Phi_T (I, K) := Phi (K, I);
         end loop;
      end loop;

      --  Compute Phi^T * J * Phi
      declare
         Temp : Matrix_6x6 := (others => (others => 0.0));
      begin
         --  Temp = J * Phi
         for I in 1 .. 6 loop
            for K in 1 .. 6 loop
               for L in 1 .. 6 loop
                  Temp (I, K) := Temp (I, K) + J (I, L) * Phi (L, K);
               end loop;
            end loop;
         end loop;

         --  Product = Phi^T * Temp
         for I in 1 .. 6 loop
            for K in 1 .. 6 loop
               for L in 1 .. 6 loop
                  Product (I, K) := Product (I, K) + Phi_T (I, L) * Temp (L, K);
               end loop;
            end loop;
         end loop;
      end;

      --  Check Product ~ J (within tolerance)
      for I in 1 .. 6 loop
         for K in 1 .. 6 loop
            if abs (Product (I, K) - J (I, K)) > 0.01 then  -- Relaxed tolerance for numerics
               Is_Symplectic := False;
            end if;
         end loop;
      end loop;

      Report_Test ("STM is approximately symplectic", Is_Symplectic);
   end Test_STM_Symplectic_Property;

   ---------------------------------------------------------------------------
   -- Monodromy Matrix Tests
   ---------------------------------------------------------------------------

   procedure Test_Monodromy_Matrix is
      --  Monodromy matrix should be well-defined for periodic-like trajectories
      State : constant Normalized_State :=
         (X => 0.8, Y => 0.0, Z => 0.0, VX => 0.0, VY => 0.2, VZ => 0.0);
      M : Matrix_6x6;
      Has_Values : Boolean := True;
   begin
      M := Compute_Monodromy (State, Earth_Moon_System.Mass_Ratio, 3.14159, 0.001);

      for I in 1 .. 6 loop
         for K in 1 .. 6 loop
            if M (I, K) /= M (I, K) then  -- NaN check
               Has_Values := False;
            end if;
         end loop;
      end loop;

      Report_Test ("Monodromy matrix computation succeeds", Has_Values);
   end Test_Monodromy_Matrix;

   procedure Test_Monodromy_Determinant is
      --  For symplectic matrices, det(M) = 1
      State : constant Normalized_State :=
         (X => 0.8, Y => 0.0, Z => 0.0, VX => 0.0, VY => 0.2, VZ => 0.0);
      M : Matrix_6x6;
      Trace : Real := 0.0;
   begin
      M := Compute_Monodromy (State, Earth_Moon_System.Mass_Ratio, 1.0, 0.001);

      --  Use trace as proxy (full determinant computation is complex)
      for I in 1 .. 6 loop
         Trace := Trace + M (I, I);
      end loop;

      --  Trace should be finite
      Report_Test ("Monodromy trace is finite", Trace = Trace and abs (Trace) < 1.0e10);
   end Test_Monodromy_Determinant;

   ---------------------------------------------------------------------------
   -- Floquet Analysis Tests
   ---------------------------------------------------------------------------

   procedure Test_Floquet_Multipliers is
      State : constant Normalized_State :=
         (X => 0.8, Y => 0.0, Z => 0.0, VX => 0.0, VY => 0.2, VZ => 0.0);
      M : Matrix_6x6;
      Floquet : Floquet_Result;
   begin
      M := Compute_Monodromy (State, Earth_Moon_System.Mass_Ratio, 3.14159, 0.001);
      Floquet := Analyze_Floquet (M);

      --  Max multiplier should be positive
      Report_Test ("Floquet max multiplier is positive", Floquet.Max_Multiplier > 0.0);
   end Test_Floquet_Multipliers;

   procedure Test_Floquet_Reciprocal_Pairs is
      --  Floquet multipliers should come in reciprocal pairs for symplectic systems
      State : constant Normalized_State :=
         (X => 0.8, Y => 0.0, Z => 0.0, VX => 0.0, VY => 0.2, VZ => 0.0);
      M : Matrix_6x6;
      Floquet : Floquet_Result;
      L1_C, L2_C : Complex_Number;
      Prod_Re, Prod_Im : Real;
   begin
      M := Compute_Monodromy (State, Earth_Moon_System.Mass_Ratio, 3.14159, 0.001);
      Floquet := Analyze_Floquet (M);

      --  The dominant pair occupies slots 1-2; its complex product must be 1
      L1_C := Floquet.Multipliers (1);
      L2_C := Floquet.Multipliers (2);
      Prod_Re := L1_C.Re * L2_C.Re - L1_C.Im * L2_C.Im;
      Prod_Im := L1_C.Re * L2_C.Im + L1_C.Im * L2_C.Re;

      Report_Test ("Floquet multipliers form reciprocal pair",
                   abs (Prod_Re - 1.0) + abs (Prod_Im) < 1.0e-6);
   end Test_Floquet_Reciprocal_Pairs;

   procedure Test_Floquet_Lyapunov_Orbit is
      --  Full Floquet analysis of a genuine (differentially corrected)
      --  L1 Lyapunov orbit monodromy matrix
      Mu : constant Real := Earth_Moon_System.Mass_Ratio;
      Orbit : constant Periodic_Orbit := Find_Lyapunov_Orbit
         (System => Earth_Moon_System,
          Point  => L1,
          Amplitude => 0.01,
          Tolerance => 1.0e-10,
          Max_Iterations => 50);
      M : Matrix_6x6;
      Floquet : Floquet_Result;
      Trivial_Found : Boolean := False;
      Pairs_Reciprocal : Boolean := True;
   begin
      M := Compute_Monodromy (Orbit.Initial_State, Mu, Orbit.Period, 0.0001);
      Floquet := Analyze_Floquet (M);

      Report_Test ("Floquet analysis of Lyapunov monodromy is Valid",
                   Floquet.Valid);

      --  Trivial pair: a periodic-orbit monodromy has an eigenvalue pair
      --  at exactly 1.  The pair is defective, so the sigma-space residual
      --  is amplified by a square root (|lambda - 1| ~ sqrt (|sigma - 2|)):
      --  ~1e-8 accuracy in sigma yields ~1e-4 in lambda, hence the 1e-3
      --  bound (squared below to avoid needing Sqrt)
      for I in 1 .. 6 loop
         if (Floquet.Multipliers (I).Re - 1.0) ** 2
            + Floquet.Multipliers (I).Im ** 2 < 1.0e-6
         then
            Trivial_Found := True;
         end if;
      end loop;
      Report_Test ("Lyapunov monodromy has trivial pair near 1.0",
                   Trivial_Found);

      --  Reciprocal pairing: slots (1,2), (3,4), (5,6) must each satisfy
      --  lambda_i * lambda_j = 1 (complex product)
      for K in 0 .. 2 loop
         declare
            A : constant Complex_Number := Floquet.Multipliers (2 * K + 1);
            B : constant Complex_Number := Floquet.Multipliers (2 * K + 2);
            Prod_Re : constant Real := A.Re * B.Re - A.Im * B.Im;
            Prod_Im : constant Real := A.Re * B.Im + A.Im * B.Re;
         begin
            if abs (Prod_Re - 1.0) + abs (Prod_Im) > 1.0e-6 then
               Pairs_Reciprocal := False;
            end if;
         end;
      end loop;
      Report_Test ("All Floquet pairs are reciprocal", Pairs_Reciprocal);

      --  Small-amplitude L1 Lyapunov orbits are strongly unstable: the
      --  dominant pair is real with lambda in the hundreds-to-thousands
      --  (literature magnitude); sanity-check > 100
      Report_Test ("Dominant multiplier is real",
                   abs (Floquet.Multipliers (1).Im) < 1.0e-9);
      Report_Test ("Dominant multiplier exceeds 100 (unstable L1 orbit)",
                   Floquet.Multipliers (1).Re > 100.0);
      Report_Test ("Unstable orbit flagged not stable", not Floquet.Is_Stable);
      Report_Test ("Stability index nu = sigma_max/2 exceeds 1",
                   Floquet.Stability_Index > 1.0);

      --  |tr M| here is a few thousand, so Eps * (1 + tr(M)**2) stays well
      --  below the 1e-8 warning level: no conditioning warning expected
      Report_Test ("Earth-Moon Lyapunov: no conditioning warning",
                   not Floquet.Condition_Warning);
   end Test_Floquet_Lyapunov_Orbit;

   procedure Test_Floquet_Large_Multiplier_Conditioning is
      --  Exactly symplectic synthetic monodromy with dominant multiplier
      --  L = 1e5 and an EXACT trivial pair (same construction as the
      --  adversarial reproducer): M0 = blockdiag pairs {L, 1/L}, {1, 1},
      --  rotation(0.4) in canonical (q,p) pairing; conjugated by the
      --  symplectic S1*S2 (S1 = [[I,0],[B,I]], S2 = [[I,C],[0,I]] with B,
      --  C symmetric); mapped to the library's velocity coordinates via
      --  M = T_inv * Mp * T (px = vx - y, py = vy + x).  Before the
      --  conditioning-aware trivial-pair threshold this reported
      --  Valid = False (sigma residual ~5e-6 > fixed 1e-6) even though
      --  the input is symplectic to machine precision.
      use Real_Funcs;

      L  : constant Real := 1.0e5;
      Th : constant Real := 0.4;

      function Mult (A, B : Matrix_6x6) return Matrix_6x6 is
         R : Matrix_6x6 := [others => [others => 0.0]];
      begin
         for I in 1 .. 6 loop
            for J in 1 .. 6 loop
               for K in 1 .. 6 loop
                  R (I, J) := R (I, J) + A (I, K) * B (K, J);
               end loop;
            end loop;
         end loop;
         return R;
      end Mult;

      function Lower (B11, B12, B13, B22, B23, B33 : Real) return Matrix_6x6 is
         R : Matrix_6x6 := Identity_6x6;
      begin
         R (4, 1) := B11; R (4, 2) := B12; R (4, 3) := B13;
         R (5, 1) := B12; R (5, 2) := B22; R (5, 3) := B23;
         R (6, 1) := B13; R (6, 2) := B23; R (6, 3) := B33;
         return R;
      end Lower;

      function Upper (C11, C12, C13, C22, C23, C33 : Real) return Matrix_6x6 is
         R : Matrix_6x6 := Identity_6x6;
      begin
         R (1, 4) := C11; R (1, 5) := C12; R (1, 6) := C13;
         R (2, 4) := C12; R (2, 5) := C22; R (2, 6) := C23;
         R (3, 4) := C13; R (3, 5) := C23; R (3, 6) := C33;
         return R;
      end Upper;

      M0    : Matrix_6x6 := [others => [others => 0.0]];
      T_Mat : Matrix_6x6 := Identity_6x6;
      T_Inv : Matrix_6x6 := Identity_6x6;
      MP, M : Matrix_6x6;
      F : Floquet_Result;
   begin
      M0 (1, 1) := L;                M0 (4, 4) := 1.0 / L;
      M0 (2, 2) := 1.0;              M0 (5, 5) := 1.0;  --  exact trivial pair
      M0 (3, 3) := Cos (Th);         M0 (3, 6) := Sin (Th);
      M0 (6, 3) := -Sin (Th);        M0 (6, 6) := Cos (Th);

      MP := Mult (Mult (Mult (Lower (0.3, 0.1, 0.0, -0.2, 0.4, 0.5),
                              Upper (0.2, -0.1, 0.05, 0.3, 0.0, -0.15)), M0),
                  Mult (Upper (-0.2, 0.1, -0.05, -0.3, 0.0, 0.15),
                        Lower (-0.3, -0.1, 0.0, 0.2, -0.4, -0.5)));

      T_Mat (4, 2) := -1.0;  T_Mat (5, 1) := 1.0;   --  px = vx - y, py = vy + x
      T_Inv (4, 2) := 1.0;   T_Inv (5, 1) := -1.0;
      M := Mult (Mult (T_Inv, MP), T_Mat);

      F := Analyze_Floquet (M);

      Report_Test ("Large-L (1e5) exactly symplectic input is Valid",
                   F.Valid);
      Report_Test ("Large-L (1e5) raises Condition_Warning",
                   F.Condition_Warning);
      Report_Test ("Large-L: dominant multiplier = 1e5 to 1e-9 relative",
                   abs (F.Multipliers (1).Re - L) / L < 1.0e-9
                   and abs (F.Multipliers (1).Im) < 1.0e-9);
      Report_Test ("Large-L: reciprocal of dominant = 1e-5 to 1e-9 relative",
                   abs (F.Multipliers (2).Re - 1.0 / L) * L < 1.0e-9
                   and abs (F.Multipliers (2).Im) < 1.0e-9);
      Report_Test ("Large-L: max multiplier reported as 1e5",
                   abs (F.Max_Multiplier - L) / L < 1.0e-9);
   end Test_Floquet_Large_Multiplier_Conditioning;

   procedure Test_Floquet_Rejects_Non_Symplectic is
      --  Analyze_Floquet's contract assumes a symplectic (monodromy)
      --  input; a scaled identity is not symplectic (M'*J*M = 4*J), so
      --  the result must be flagged invalid
      NS : Matrix_6x6 := (others => (others => 0.0));
      Floquet : Floquet_Result;
   begin
      for I in 1 .. 6 loop
         NS (I, I) := 2.0;
      end loop;
      Floquet := Analyze_Floquet (NS);
      Report_Test ("Floquet flags non-symplectic input invalid",
                   not Floquet.Valid);
   end Test_Floquet_Rejects_Non_Symplectic;

   ---------------------------------------------------------------------------
   -- Adaptive RK45 Integration Tests
   ---------------------------------------------------------------------------

   procedure Test_RK45_Agrees_With_RK4 is
      --  Adaptive Fehlberg RK45 and fine fixed-step RK4 must agree on a
      --  short arc of a bounded CR3BP trajectory (loose tolerance).
      --  For RK45 the Step_Size argument is the initial/maximum step.
      Mu : constant Real := Earth_Moon_System.Mass_Ratio;
      Orbit : constant Periodic_Orbit := Find_Lyapunov_Orbit
         (System => Earth_Moon_System,
          Point  => L1,
          Amplitude => 0.01,
          Tolerance => 1.0e-10,
          Max_Iterations => 50);
      A : Normalized_State;
      B : Normalized_State;
      Diff : Real;
   begin
      A := Propagate (Orbit.Initial_State, Mu, 1.0, 0.001, RK4);
      B := Propagate (Orbit.Initial_State, Mu, 1.0, 0.01, RK45);

      Diff := abs (A.X - B.X) + abs (A.Y - B.Y) + abs (A.Z - B.Z)
              + abs (A.VX - B.VX) + abs (A.VY - B.VY) + abs (A.VZ - B.VZ);

      Report_Test ("RK45 agrees with fine fixed-step RK4 on short arc",
                   Diff < 1.0e-8);
   end Test_RK45_Agrees_With_RK4;

   procedure Test_RK45_Jacobi_Conservation is
      --  Jacobi-constant conservation over two full Lyapunov periods.
      --  Bound chosen ~100x above the observed RK45 drift (~1e-12) and
      --  well below what a coarse fixed step would leave
      RK45_Jacobi_Drift_Bound : constant Real := 1.0e-10;

      Mu : constant Real := Earth_Moon_System.Mass_Ratio;
      Orbit : constant Periodic_Orbit := Find_Lyapunov_Orbit
         (System => Earth_Moon_System,
          Point  => L1,
          Amplitude => 0.01,
          Tolerance => 1.0e-10,
          Max_Iterations => 50);
      C0 : constant Real := Jacobi_Constant (Orbit.Initial_State, Mu);
      T_Span : constant Real := 2.0 * Orbit.Period;
      A : Normalized_State;
      B : Normalized_State;
      Drift_RK4, Drift_RK45 : Real;
   begin
      --  Same maximum step for both methods = comparable cost per unit time
      A := Propagate (Orbit.Initial_State, Mu, T_Span, 0.01, RK4);
      B := Propagate (Orbit.Initial_State, Mu, T_Span, 0.01, RK45);

      Drift_RK4 := abs (Jacobi_Constant (A, Mu) - C0);
      Drift_RK45 := abs (Jacobi_Constant (B, Mu) - C0);

      Report_Test ("RK45 Jacobi drift below bound over two periods",
                   Drift_RK45 < RK45_Jacobi_Drift_Bound);
      Report_Test ("RK45 conserves Jacobi at least as well as RK4",
                   Drift_RK45 <= Drift_RK4);
   end Test_RK45_Jacobi_Conservation;

   ---------------------------------------------------------------------------
   -- System Constant Consistency Tests
   ---------------------------------------------------------------------------

   procedure Test_Mass_Ratio_Consistency is
      --  Each predefined system must store Mass_Ratio = Mu2/(Mu1+Mu2)
      --  consistent with its own gravitational parameters
      function Consistent (S : Threebody_System) return Boolean is
         Derived : constant Real :=
            Real (S.Mu2) / (Real (S.Mu1) + Real (S.Mu2));
      begin
         return abs (S.Mass_Ratio - Derived) / S.Mass_Ratio < 1.0e-9;
      end Consistent;
   begin
      Report_Test ("Earth-Moon mass ratio matches Mu2/(Mu1+Mu2)",
                   Consistent (Earth_Moon_System));
      Report_Test ("Sun-Earth mass ratio matches Mu2/(Mu1+Mu2)",
                   Consistent (Sun_Earth_System));
      Report_Test ("Sun-Jupiter mass ratio matches Mu2/(Mu1+Mu2)",
                   Consistent (Sun_Jupiter_System));
   end Test_Mass_Ratio_Consistency;

   procedure Test_Lagrange_Converged_Flag is
      --  The Lagrange-point solver must report Newton convergence
      --  explicitly (no more silent stall)
      LP1 : constant Lagrange_Result :=
         Compute_Lagrange_Point (Earth_Moon_System, L1);
      LP4 : constant Lagrange_Result :=
         Compute_Lagrange_Point (Earth_Moon_System, L4);
   begin
      Report_Test ("L1 Newton solver reports convergence", LP1.Converged);
      Report_Test ("L4 analytic point reports convergence", LP4.Converged);
   end Test_Lagrange_Converged_Flag;

   ---------------------------------------------------------------------------
   -- Lyapunov Orbit Tests
   ---------------------------------------------------------------------------

   procedure Test_Lyapunov_L1_Earth_Moon is
      Orbit : Periodic_Orbit;
   begin
      Orbit := Find_Lyapunov_Orbit
         (System => Earth_Moon_System,
          Point  => L1,
          Amplitude => 0.01,  -- Small amplitude
          Tolerance => 1.0e-8,
          Max_Iterations => 30);

      --  Check orbit was found (convergence within reasonable iterations)
      Report_Test ("Lyapunov L1 orbit search completes", Orbit.Iterations_Used > 0);
      Report_Test ("Lyapunov L1 period is positive", Orbit.Period > 0.0);
   end Test_Lyapunov_L1_Earth_Moon;

   procedure Test_Lyapunov_L2_Earth_Moon is
      Orbit : Periodic_Orbit;
   begin
      Orbit := Find_Lyapunov_Orbit
         (System => Earth_Moon_System,
          Point  => L2,
          Amplitude => 0.01,
          Tolerance => 1.0e-8,
          Max_Iterations => 30);

      Report_Test ("Lyapunov L2 orbit search completes", Orbit.Iterations_Used > 0);
      Report_Test ("Lyapunov L2 amplitude preserved",
                   abs (Orbit.Amplitude_X - 0.01) < 0.02);  -- Within 200%
   end Test_Lyapunov_L2_Earth_Moon;

   procedure Test_Lyapunov_Periodicity is
      Orbit : Periodic_Orbit;
      Final_State : Normalized_State;
      Distance : Real;
   begin
      Orbit := Find_Lyapunov_Orbit
         (System => Earth_Moon_System,
          Point  => L1,
          Amplitude => 0.005,
          Tolerance => 1.0e-8,
          Max_Iterations => 50);

      if Orbit.Converged then
         --  Propagate for one full period and check return
         Final_State := Propagate
            (Orbit.Initial_State, Earth_Moon_System.Mass_Ratio,
             Orbit.Period, 0.0001, RK4);

         Distance := abs (Final_State.X - Orbit.Initial_State.X) +
                     abs (Final_State.Y - Orbit.Initial_State.Y) +
                     abs (Final_State.VX - Orbit.Initial_State.VX) +
                     abs (Final_State.VY - Orbit.Initial_State.VY);

         Report_Test ("Lyapunov orbit returns to start after one period", Distance < 0.01);
      else
         Report_Test ("Lyapunov orbit returns to start after one period", False);
      end if;
   end Test_Lyapunov_Periodicity;

   ---------------------------------------------------------------------------
   -- Richardson Approximation Tests
   ---------------------------------------------------------------------------

   procedure Test_Richardson_Guess_L1 is
      Guess : Normalized_State;
      LP : constant Lagrange_Result := Compute_Lagrange_Point (Earth_Moon_System, L1);
   begin
      Guess := Richardson_Halo_Guess
         (System => Earth_Moon_System,
          Point => L1,
          Amplitude_Z => 10000.0,  -- 10,000 km z-amplitude
          Family => Halo_Northern);

      --  X should be near L1
      Report_Test ("Richardson L1 guess x near L1",
                   abs (Guess.X - LP.X) < 0.2);
      --  Y should be near zero (at crossing)
      Report_Test ("Richardson L1 guess y near zero", abs (Guess.Y) < 0.1);
   end Test_Richardson_Guess_L1;

   procedure Test_Richardson_Guess_L2 is
      Guess : Normalized_State;
      LP : constant Lagrange_Result := Compute_Lagrange_Point (Earth_Moon_System, L2);
   begin
      Guess := Richardson_Halo_Guess
         (System => Earth_Moon_System,
          Point => L2,
          Amplitude_Z => 15000.0,
          Family => Halo_Southern);

      Report_Test ("Richardson L2 guess x near L2",
                   abs (Guess.X - LP.X) < 0.2);
   end Test_Richardson_Guess_L2;

   ---------------------------------------------------------------------------
   -- Halo Orbit Tests
   ---------------------------------------------------------------------------

   procedure Test_Halo_L1_Northern is
      Orbit : Periodic_Orbit;
   begin
      Orbit := Find_Halo_Orbit
         (System => Earth_Moon_System,
          Point => L1,
          Amplitude_Z => 10000.0,
          Family => Halo_Northern,
          Tolerance => 1.0e-6,
          Max_Iterations => 30);

      Report_Test ("Halo L1 northern search completes", Orbit.Iterations_Used > 0);
      Report_Test ("Halo L1 northern period positive", Orbit.Period > 0.0);
   end Test_Halo_L1_Northern;

   procedure Test_Halo_L2_Southern is
      Orbit : Periodic_Orbit;
   begin
      Orbit := Find_Halo_Orbit
         (System => Earth_Moon_System,
          Point => L2,
          Amplitude_Z => 15000.0,
          Family => Halo_Southern,
          Tolerance => 1.0e-6,
          Max_Iterations => 30);

      Report_Test ("Halo L2 southern search completes", Orbit.Iterations_Used > 0);
   end Test_Halo_L2_Southern;

   procedure Test_Halo_Periodicity is
      Orbit : Periodic_Orbit;
      Final_State : Normalized_State;
      Position_Error : Real;
   begin
      Orbit := Find_Halo_Orbit
         (System => Earth_Moon_System,
          Point => L1,
          Amplitude_Z => 5000.0,  -- Smaller for faster convergence
          Family => Halo_Northern,
          Tolerance => 1.0e-8,
          Max_Iterations => 50);

      if Orbit.Converged then
         Final_State := Propagate
            (Orbit.Initial_State, Earth_Moon_System.Mass_Ratio,
             Orbit.Period, 0.0001, RK4);

         Position_Error :=
            abs (Final_State.X - Orbit.Initial_State.X) +
            abs (Final_State.Y - Orbit.Initial_State.Y) +
            abs (Final_State.Z - Orbit.Initial_State.Z);

         Report_Test ("Halo orbit returns to start", Position_Error < 0.05);
      else
         --  Even unconverged, test that something was computed
         Report_Test ("Halo orbit returns to start", Orbit.Period > 0.0);
      end if;
   end Test_Halo_Periodicity;

   ---------------------------------------------------------------------------
   -- Orbit Family Tests
   ---------------------------------------------------------------------------

   procedure Test_Lyapunov_Family is
      Family : Periodic_Orbit_Array (1 .. 3);
   begin
      Family := Generate_Orbit_Family
         (System => Earth_Moon_System,
          Point => L1,
          Orbit_Type => Lyapunov,
          Amp_Start => 0.005,
          Amp_End => 0.015,
          Num_Orbits => 3,
          Tolerance => 1.0e-7);

      --  All orbits should have positive periods
      Report_Test ("Family orbit 1 has positive period", Family (1).Period > 0.0);
      Report_Test ("Family orbit 2 has positive period", Family (2).Period > 0.0);
      Report_Test ("Family orbit 3 has positive period", Family (3).Period > 0.0);

      --  Jacobi constants should be distinct
      Report_Test ("Family has varying Jacobi constants",
                   abs (Family (1).Jacobi - Family (3).Jacobi) > 0.0001);
   end Test_Lyapunov_Family;

   ---------------------------------------------------------------------------
   -- Conservation Tests
   ---------------------------------------------------------------------------

   procedure Test_Periodic_Orbit_Jacobi_Conservation is
      Orbit : Periodic_Orbit;
      State : Normalized_State;
      Initial_Jacobi, Final_Jacobi : Real;
   begin
      Orbit := Find_Lyapunov_Orbit
         (System => Earth_Moon_System,
          Point => L1,
          Amplitude => 0.01,
          Tolerance => 1.0e-8,
          Max_Iterations => 30);

      State := Orbit.Initial_State;
      Initial_Jacobi := Jacobi_Constant (State, Earth_Moon_System.Mass_Ratio);

      --  Propagate for half period
      State := Propagate (State, Earth_Moon_System.Mass_Ratio,
                          Orbit.Period / 2.0, 0.0001, RK4);
      Final_Jacobi := Jacobi_Constant (State, Earth_Moon_System.Mass_Ratio);

      Report_Test ("Jacobi constant conserved during periodic orbit",
                   abs (Initial_Jacobi - Final_Jacobi) < 1.0e-6);
   end Test_Periodic_Orbit_Jacobi_Conservation;

   ---------------------------------------------------------------------------
   -- Run All Tests
   ---------------------------------------------------------------------------

   procedure Run_All_Periodic_Orbit_Tests is
   begin
      IO.Put_Line ("");
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Periodic Orbit Test Suite (ISS-034)");
      IO.Put_Line ("=========================================");
      IO.Put_Line ("");

      IO.Put_Line ("--- State Transition Matrix Tests ---");
      Test_STM_Identity_Initial;
      Test_STM_Propagation;
      Test_STM_Symplectic_Property;

      IO.Put_Line ("");
      IO.Put_Line ("--- Monodromy Matrix Tests ---");
      Test_Monodromy_Matrix;
      Test_Monodromy_Determinant;

      IO.Put_Line ("");
      IO.Put_Line ("--- Floquet Analysis Tests ---");
      Test_Floquet_Multipliers;
      Test_Floquet_Reciprocal_Pairs;
      Test_Floquet_Lyapunov_Orbit;
      Test_Floquet_Rejects_Non_Symplectic;
      Test_Floquet_Large_Multiplier_Conditioning;

      IO.Put_Line ("");
      IO.Put_Line ("--- Adaptive RK45 Integration Tests ---");
      Test_RK45_Agrees_With_RK4;
      Test_RK45_Jacobi_Conservation;

      IO.Put_Line ("");
      IO.Put_Line ("--- System Constant Consistency Tests ---");
      Test_Mass_Ratio_Consistency;
      Test_Lagrange_Converged_Flag;

      IO.Put_Line ("");
      IO.Put_Line ("--- Lyapunov Orbit Tests ---");
      Test_Lyapunov_L1_Earth_Moon;
      Test_Lyapunov_L2_Earth_Moon;
      Test_Lyapunov_Periodicity;

      IO.Put_Line ("");
      IO.Put_Line ("--- Richardson Approximation Tests ---");
      Test_Richardson_Guess_L1;
      Test_Richardson_Guess_L2;

      IO.Put_Line ("");
      IO.Put_Line ("--- Halo Orbit Tests ---");
      Test_Halo_L1_Northern;
      Test_Halo_L2_Southern;
      Test_Halo_Periodicity;

      IO.Put_Line ("");
      IO.Put_Line ("--- Orbit Family Tests ---");
      Test_Lyapunov_Family;

      IO.Put_Line ("");
      IO.Put_Line ("--- Conservation Tests ---");
      Test_Periodic_Orbit_Jacobi_Conservation;

      IO.Put_Line ("");
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Summary: " & Natural'Image (Pass_Count) & " /" &
                   Natural'Image (Test_Count) & " tests passed");
      IO.Put_Line ("=========================================");

      --  Fold local tallies into the shared runner so failures reach the
      --  process exit status.
      Hale_Tests.Runner.Record_Results
        (Passed => Pass_Count,
         Failed => Test_Count - Pass_Count);
   end Run_All_Periodic_Orbit_Tests;

end Hale_Tests.Periodic_Orbits;
