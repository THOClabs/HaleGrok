-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Three-Body Package Body (CR3BP)
-------------------------------------------------------------------------------

with Ada.Numerics.Generic_Elementary_Functions;

package body Hale_Orbital.Threebody
   with SPARK_Mode => Off  --  Body uses generic instantiation
is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   --  Tolerance for iterative computations
   Tolerance : constant Real := 1.0e-12;
   Max_Iterations : constant Positive := 100;

   --  Adaptive RK45 (Fehlberg 4(5)) step control -- see Propagate in the spec
   RK45_Error_Tol : constant Real := 1.0e-10;
   --  Per-step local error tolerance: Euclidean norm of the difference
   --  between the embedded 4th- and 5th-order solutions.  Matches the
   --  Python oracle default (integrators.py, rk45_step, tol=1e-10).

   RK45_Safety : constant Real := 0.9;
   --  Safety factor of the step-size controller

   RK45_Min_Step : constant Real := 1.0e-14;
   --  Absolute floor on the adaptive step: a step at the floor is accepted
   --  even if the error test fails, guaranteeing forward progress

   ---------------------------------------------------------------------------
   -- Helper Functions
   ---------------------------------------------------------------------------

   --  Distance from point to primary 1 (at x = -mu)
   function R1 (X, Y, Z : Real; Mu : Real) return Real is
      DX : constant Real := X + Mu;
   begin
      return Sqrt (DX * DX + Y * Y + Z * Z);
   end R1;
   pragma Inline (R1);

   --  Distance from point to primary 2 (at x = 1-mu)
   function R2 (X, Y, Z : Real; Mu : Real) return Real is
      DX : constant Real := X - (1.0 - Mu);
   begin
      return Sqrt (DX * DX + Y * Y + Z * Z);
   end R2;
   pragma Inline (R2);

   ---------------------------------------------------------------------------
   -- Lagrange Point Computation
   ---------------------------------------------------------------------------

   function Compute_Lagrange_Point
      (System : Threebody_System;
       Point  : Lagrange_Point) return Lagrange_Result
   is
      Mu : constant Real := System.Mass_Ratio;
      X, Y : Real;
      Gamma : Real;  -- For L1, L2, L3 computation
      Result : Lagrange_Result;
      Newton_Converged : Boolean := False;  -- Set by the Newton loops below
   begin
      Result.Point := Point;

      case Point is
         when L1 =>
            --  L1: Between primaries, solve quintic equation
            --  Initial guess: gamma = (mu/3)^(1/3) from primary 2
            Gamma := (Mu / 3.0) ** (1.0 / 3.0);

            --  Newton-Raphson iteration for L1
            for I in 1 .. Max_Iterations loop
               declare
                  G2 : constant Real := Gamma * Gamma;
                  G3 : constant Real := G2 * Gamma;
                  G4 : constant Real := G3 * Gamma;
                  G5 : constant Real := G4 * Gamma;

                  --  f(gamma) = gamma^5 - (3-mu)*gamma^4 + (3-2*mu)*gamma^3
                  --             - mu*gamma^2 + 2*mu*gamma - mu
                  F : constant Real := G5 - (3.0 - Mu) * G4 + (3.0 - 2.0 * Mu) * G3
                                       - Mu * G2 + 2.0 * Mu * Gamma - Mu;

                  --  f'(gamma) for Newton's method
                  FP : constant Real := 5.0 * G4 - 4.0 * (3.0 - Mu) * G3
                                        + 3.0 * (3.0 - 2.0 * Mu) * G2
                                        - 2.0 * Mu * Gamma + 2.0 * Mu;

                  Delta_Val : Real;
               begin
                  if abs (FP) < 1.0e-15 then
                     exit;
                  end if;
                  Delta_Val := F / FP;
                  Gamma := Gamma - Delta_Val;
                  if abs (Delta_Val) < Tolerance then
                     Newton_Converged := True;
                     exit;
                  end if;
               end;
            end loop;

            X := 1.0 - Mu - Gamma;
            Y := 0.0;

         when L2 =>
            --  L2: Beyond primary 2 (away from primary 1)
            Gamma := (Mu / 3.0) ** (1.0 / 3.0);

            for I in 1 .. Max_Iterations loop
               declare
                  G2 : constant Real := Gamma * Gamma;
                  G3 : constant Real := G2 * Gamma;
                  G4 : constant Real := G3 * Gamma;
                  G5 : constant Real := G4 * Gamma;

                  F : constant Real := G5 + (3.0 - Mu) * G4 + (3.0 - 2.0 * Mu) * G3
                                       - Mu * G2 - 2.0 * Mu * Gamma - Mu;
                  FP : constant Real := 5.0 * G4 + 4.0 * (3.0 - Mu) * G3
                                        + 3.0 * (3.0 - 2.0 * Mu) * G2
                                        - 2.0 * Mu * Gamma - 2.0 * Mu;
                  Delta_Val : Real;
               begin
                  if abs (FP) < 1.0e-15 then
                     exit;
                  end if;
                  Delta_Val := F / FP;
                  Gamma := Gamma - Delta_Val;
                  if abs (Delta_Val) < Tolerance then
                     Newton_Converged := True;
                     exit;
                  end if;
               end;
            end loop;

            X := 1.0 - Mu + Gamma;
            Y := 0.0;

         when L3 =>
            --  L3: Beyond primary 1 (opposite side from primary 2)
            Gamma := 1.0 - 7.0 * Mu / 12.0;  -- Initial approximation

            for I in 1 .. Max_Iterations loop
               declare
                  G2 : constant Real := Gamma * Gamma;
                  G3 : constant Real := G2 * Gamma;
                  G4 : constant Real := G3 * Gamma;
                  G5 : constant Real := G4 * Gamma;

                  F : constant Real := G5 + (2.0 + Mu) * G4 + (1.0 + 2.0 * Mu) * G3
                                       - (1.0 - Mu) * G2 - 2.0 * (1.0 - Mu) * Gamma
                                       - (1.0 - Mu);
                  FP : constant Real := 5.0 * G4 + 4.0 * (2.0 + Mu) * G3
                                        + 3.0 * (1.0 + 2.0 * Mu) * G2
                                        - 2.0 * (1.0 - Mu) * Gamma - 2.0 * (1.0 - Mu);
                  Delta_Val : Real;
               begin
                  if abs (FP) < 1.0e-15 then
                     exit;
                  end if;
                  Delta_Val := F / FP;
                  Gamma := Gamma - Delta_Val;
                  if abs (Delta_Val) < Tolerance then
                     Newton_Converged := True;
                     exit;
                  end if;
               end;
            end loop;

            X := -Mu - Gamma;
            Y := 0.0;

         when L4 =>
            --  L4: Leading equilateral point (60 degrees ahead)
            X := 0.5 - Mu;
            Y := Sqrt (3.0) / 2.0;
            Newton_Converged := True;  -- Analytic solution, no iteration

         when L5 =>
            --  L5: Trailing equilateral point (60 degrees behind)
            X := 0.5 - Mu;
            Y := -Sqrt (3.0) / 2.0;
            Newton_Converged := True;  -- Analytic solution, no iteration
      end case;

      Result.X := X;
      Result.Y := Y;
      Result.Distance := Distance_Km (abs (X) * Real (System.Distance));
      Result.Converged := Newton_Converged;

      return Result;
   end Compute_Lagrange_Point;

   function Compute_All_Lagrange_Points
      (System : Threebody_System) return Lagrange_Array
   is
      Result : Lagrange_Array;
   begin
      for P in Lagrange_Point loop
         Result (P) := Compute_Lagrange_Point (System, P);
      end loop;
      return Result;
   end Compute_All_Lagrange_Points;

   ---------------------------------------------------------------------------
   -- CR3BP Equations of Motion
   ---------------------------------------------------------------------------

   function Pseudo_Potential
      (X, Y, Z : Real;
       Mu      : Real) return Real
   is
      R1_Val : constant Real := R1 (X, Y, Z, Mu);
      R2_Val : constant Real := R2 (X, Y, Z, Mu);
   begin
      --  Omega = 0.5*(x^2 + y^2) + (1-mu)/r1 + mu/r2
      return 0.5 * (X * X + Y * Y) + (1.0 - Mu) / R1_Val + Mu / R2_Val;
   end Pseudo_Potential;

   procedure Compute_Acceleration
      (State : in  Normalized_State;
       Mu    : in  Real;
       AX    : out Real;
       AY    : out Real;
       AZ    : out Real)
   is
      X  : constant Real := State.X;
      Y  : constant Real := State.Y;
      Z  : constant Real := State.Z;
      VX : constant Real := State.VX;
      VY : constant Real := State.VY;

      R1_Val : constant Real := R1 (X, Y, Z, Mu);
      R2_Val : constant Real := R2 (X, Y, Z, Mu);
      R1_3   : constant Real := R1_Val * R1_Val * R1_Val;
      R2_3   : constant Real := R2_Val * R2_Val * R2_Val;

      --  Partial derivatives of pseudo-potential
      DX_Plus_Mu  : constant Real := X + Mu;
      DX_Minus    : constant Real := X - (1.0 - Mu);
   begin
      --  Equations of motion in rotating frame:
      --  x'' = 2*y' + x - (1-mu)*(x+mu)/r1^3 - mu*(x-1+mu)/r2^3
      --  y'' = -2*x' + y - (1-mu)*y/r1^3 - mu*y/r2^3
      --  z'' = -(1-mu)*z/r1^3 - mu*z/r2^3

      AX := 2.0 * VY + X - (1.0 - Mu) * DX_Plus_Mu / R1_3 - Mu * DX_Minus / R2_3;
      AY := -2.0 * VX + Y - (1.0 - Mu) * Y / R1_3 - Mu * Y / R2_3;
      AZ := -(1.0 - Mu) * Z / R1_3 - Mu * Z / R2_3;
   end Compute_Acceleration;

   function Jacobi_Constant
      (State : Normalized_State;
       Mu    : Real) return Real
   is
      V2 : constant Real := State.VX * State.VX + State.VY * State.VY
                           + State.VZ * State.VZ;
      Omega : constant Real := Pseudo_Potential (State.X, State.Y, State.Z, Mu);
   begin
      --  C = 2*Omega - v^2 (Jacobi integral)
      return 2.0 * Omega - V2;
   end Jacobi_Constant;

   ---------------------------------------------------------------------------
   -- State Propagation
   ---------------------------------------------------------------------------

   function Propagate
      (Initial_State : Normalized_State;
       Mu            : Real;
       T_Final       : Real;
       Step_Size     : Real := 0.001;
       Method        : Integration_Method := RK4) return Normalized_State
   is
      State : Normalized_State := Initial_State;
      T     : Real := 0.0;
      H     : Real := Step_Size;

      --  Helper: Convert state to array for RK4
      type State_Array is array (1 .. 6) of Real;

      function State_To_Array (S : Normalized_State) return State_Array is
      begin
         return (S.X, S.Y, S.Z, S.VX, S.VY, S.VZ);
      end State_To_Array;

      function Array_To_State (A : State_Array) return Normalized_State is
      begin
         return (X => A (1), Y => A (2), Z => A (3),
                 VX => A (4), VY => A (5), VZ => A (6));
      end Array_To_State;

      --  Compute derivatives (velocities and accelerations)
      function Derivatives (S : State_Array) return State_Array is
         Tmp_State : constant Normalized_State := Array_To_State (S);
         AX, AY, AZ : Real;
      begin
         Compute_Acceleration (Tmp_State, Mu, AX, AY, AZ);
         return (S (4), S (5), S (6), AX, AY, AZ);
      end Derivatives;

   begin
      case Method is
         when Euler | RK4 =>
            --  Fixed-step integration: constant step Step_Size, with the
            --  last step shortened to land exactly on T_Final
            while T < T_Final loop
               --  Adjust step size for final step
               if T + H > T_Final then
                  H := T_Final - T;
               end if;

               if Method = Euler then
                  declare
                     Y_Arr : constant State_Array := State_To_Array (State);
                     K : constant State_Array := Derivatives (Y_Arr);
                     Y_New : State_Array;
                  begin
                     for I in 1 .. 6 loop
                        Y_New (I) := Y_Arr (I) + H * K (I);
                     end loop;
                     State := Array_To_State (Y_New);
                  end;
               else
                  --  Classical 4th-order Runge-Kutta
                  declare
                     Y_Arr : constant State_Array := State_To_Array (State);
                     K1, K2, K3, K4 : State_Array;
                     Y_Temp : State_Array;
                     Y_New : State_Array;
                  begin
                     K1 := Derivatives (Y_Arr);

                     for I in 1 .. 6 loop
                        Y_Temp (I) := Y_Arr (I) + 0.5 * H * K1 (I);
                     end loop;
                     K2 := Derivatives (Y_Temp);

                     for I in 1 .. 6 loop
                        Y_Temp (I) := Y_Arr (I) + 0.5 * H * K2 (I);
                     end loop;
                     K3 := Derivatives (Y_Temp);

                     for I in 1 .. 6 loop
                        Y_Temp (I) := Y_Arr (I) + H * K3 (I);
                     end loop;
                     K4 := Derivatives (Y_Temp);

                     for I in 1 .. 6 loop
                        Y_New (I) := Y_Arr (I) + H * (K1 (I) + 2.0 * K2 (I)
                                                       + 2.0 * K3 (I) + K4 (I)) / 6.0;
                     end loop;

                     State := Array_To_State (Y_New);
                  end;
               end if;

               T := T + H;
               H := Step_Size;  -- Reset for next iteration
            end loop;

         when RK45 =>
            --  Adaptive embedded Runge-Kutta-Fehlberg 4(5).  Tableau and
            --  step controller convention match the Python oracle
            --  (python/three-body-extension/src/threebody/integrators.py,
            --  rk45_step): the 5th-order solution is advanced (local
            --  extrapolation) and the controller uses the order-5 exponent.
            --  Step_Size is the initial and MAXIMUM step; the adapted step
            --  H is carried forward across iterations and clamped so the
            --  propagation ends exactly at T_Final.
            declare
               --  Fehlberg A-matrix coefficients
               A21 : constant Real := 1.0 / 4.0;
               A31 : constant Real := 3.0 / 32.0;
               A32 : constant Real := 9.0 / 32.0;
               A41 : constant Real := 1932.0 / 2197.0;
               A42 : constant Real := -7200.0 / 2197.0;
               A43 : constant Real := 7296.0 / 2197.0;
               A51 : constant Real := 439.0 / 216.0;
               A52 : constant Real := -8.0;
               A53 : constant Real := 3680.0 / 513.0;
               A54 : constant Real := -845.0 / 4104.0;
               A61 : constant Real := -8.0 / 27.0;
               A62 : constant Real := 2.0;
               A63 : constant Real := -3544.0 / 2565.0;
               A64 : constant Real := 1859.0 / 4104.0;
               A65 : constant Real := -11.0 / 40.0;

               --  5th-order weights (solution is advanced with these)
               B1 : constant Real := 16.0 / 135.0;
               B3 : constant Real := 6656.0 / 12825.0;
               B4 : constant Real := 28561.0 / 56430.0;
               B5 : constant Real := -9.0 / 50.0;
               B6 : constant Real := 2.0 / 55.0;

               --  Embedded 4th-order weights (error estimate only)
               B1S : constant Real := 25.0 / 216.0;
               B3S : constant Real := 1408.0 / 2565.0;
               B4S : constant Real := 2197.0 / 4104.0;
               B5S : constant Real := -1.0 / 5.0;

               K1, K2, K3, K4, K5, K6 : State_Array;
               Y_Arr, Y_Temp, Y5, Y4 : State_Array;
               Err : Real;
               H_Try : Real;
               H_New : Real;
            begin
               while T < T_Final loop
                  --  Remaining time below floating-point resolution:
                  --  cannot advance T any further, so stop
                  exit when T_Final - T <=
                     4.0 * Real'Model_Epsilon * (abs (T_Final) + 1.0);

                  --  Clamp so the final step lands exactly on T_Final
                  H_Try := H;
                  if T + H_Try > T_Final then
                     H_Try := T_Final - T;
                  end if;

                  Y_Arr := State_To_Array (State);

                  K1 := Derivatives (Y_Arr);
                  for I in 1 .. 6 loop
                     Y_Temp (I) := Y_Arr (I) + H_Try * A21 * K1 (I);
                  end loop;
                  K2 := Derivatives (Y_Temp);
                  for I in 1 .. 6 loop
                     Y_Temp (I) := Y_Arr (I)
                        + H_Try * (A31 * K1 (I) + A32 * K2 (I));
                  end loop;
                  K3 := Derivatives (Y_Temp);
                  for I in 1 .. 6 loop
                     Y_Temp (I) := Y_Arr (I)
                        + H_Try * (A41 * K1 (I) + A42 * K2 (I)
                                   + A43 * K3 (I));
                  end loop;
                  K4 := Derivatives (Y_Temp);
                  for I in 1 .. 6 loop
                     Y_Temp (I) := Y_Arr (I)
                        + H_Try * (A51 * K1 (I) + A52 * K2 (I)
                                   + A53 * K3 (I) + A54 * K4 (I));
                  end loop;
                  K5 := Derivatives (Y_Temp);
                  for I in 1 .. 6 loop
                     Y_Temp (I) := Y_Arr (I)
                        + H_Try * (A61 * K1 (I) + A62 * K2 (I)
                                   + A63 * K3 (I) + A64 * K4 (I)
                                   + A65 * K5 (I));
                  end loop;
                  K6 := Derivatives (Y_Temp);

                  --  Embedded solutions and error estimate
                  Err := 0.0;
                  for I in 1 .. 6 loop
                     Y5 (I) := Y_Arr (I)
                        + H_Try * (B1 * K1 (I) + B3 * K3 (I) + B4 * K4 (I)
                                   + B5 * K5 (I) + B6 * K6 (I));
                     Y4 (I) := Y_Arr (I)
                        + H_Try * (B1S * K1 (I) + B3S * K3 (I)
                                   + B4S * K4 (I) + B5S * K5 (I));
                     Err := Err + (Y5 (I) - Y4 (I)) ** 2;
                  end loop;
                  Err := Sqrt (Err);

                  --  Step-size controller (matches the Python oracle):
                  --  safety 0.9, order-5 exponent 1/5, step change limited
                  --  to [H/10, 5*H], doubled on a zero error estimate
                  if Err > 0.0 then
                     H_New := RK45_Safety * H_Try
                        * (RK45_Error_Tol / Err) ** (1.0 / 5.0);
                     H_New := Real'Max (H_Try / 10.0,
                                        Real'Min (H_New, 5.0 * H_Try));
                  else
                     H_New := 2.0 * H_Try;
                  end if;

                  --  Step_Size doubles as the maximum step
                  H_New := Real'Min (H_New, Step_Size);

                  if Err <= RK45_Error_Tol or else H_Try <= RK45_Min_Step then
                     --  Accept: advance with the 5th-order solution
                     State := Array_To_State (Y5);
                     T := T + H_Try;
                  end if;
                  --  A rejected step is retried with the reduced H below

                  H := Real'Max (H_New, RK45_Min_Step);
               end loop;
            end;
      end case;

      return State;
   end Propagate;

   ---------------------------------------------------------------------------
   -- Stability Analysis
   ---------------------------------------------------------------------------

   function Analyze_Stability
      (System : Threebody_System;
       Point  : Lagrange_Point) return Stability_Result
   is
      Mu : constant Real := System.Mass_Ratio;
      Result : Stability_Result;
      LP : Lagrange_Result;
   begin
      LP := Compute_Lagrange_Point (System, Point);

      case Point is
         when L1 | L2 | L3 =>
            --  Collinear points are always unstable (saddle points)
            Result.Is_Stable := False;

            --  Compute eigenvalue approximation
            declare
               Gamma : constant Real := abs (LP.X - (1.0 - Mu));
               --  For L1/L2: approximate eigenvalue
               Lambda_Approx : constant Real := Sqrt (1.0 + 2.0 * (Mu / (3.0 * Gamma ** 3)));
            begin
               Result.Eigenvalue_Real := Lambda_Approx;
               Result.Eigenvalue_Imag := 0.0;
               Result.Period := 0.0;  -- Not periodic (unstable)
            end;

         when L4 | L5 =>
            --  Triangular points: stable if mu < 0.0385... (Routh's criterion)
            declare
               Critical_Mu : constant Real := (1.0 - Sqrt (69.0) / 9.0) / 2.0;
               --  Critical_Mu approximately 0.0385
            begin
               Result.Is_Stable := Mu < Critical_Mu;

               if Result.Is_Stable then
                  --  Compute oscillation frequency
                  declare
                     Omega_Sq : constant Real := 1.0 - 27.0 * Mu * (1.0 - Mu) / 4.0;
                  begin
                     if Omega_Sq > 0.0 then
                        Result.Eigenvalue_Real := 0.0;
                        Result.Eigenvalue_Imag := Sqrt (Omega_Sq);
                        Result.Period := 2.0 * 3.14159265358979 / Sqrt (Omega_Sq);
                     else
                        Result.Is_Stable := False;
                        Result.Eigenvalue_Real := Sqrt (-Omega_Sq);
                        Result.Eigenvalue_Imag := 0.0;
                        Result.Period := 0.0;
                     end if;
                  end;
               else
                  Result.Eigenvalue_Real := Sqrt (27.0 * Mu * (1.0 - Mu) / 4.0 - 1.0);
                  Result.Eigenvalue_Imag := 0.0;
                  Result.Period := 0.0;
               end if;
            end;
      end case;

      return Result;
   end Analyze_Stability;

   ---------------------------------------------------------------------------
   -- Coordinate Conversions
   ---------------------------------------------------------------------------

   function To_Normalized
      (Position : Position_Vector;
       Velocity : Velocity_Vector;
       System   : Threebody_System) return Normalized_State
   is
      L : constant Real := Real (System.Distance);
      Mu_Total : constant Real := Real (System.Mu1) + Real (System.Mu2);
      N : constant Real := Sqrt (Mu_Total / (L * L * L));  -- Mean motion
   begin
      return (X  => Position (1) / L,
              Y  => Position (2) / L,
              Z  => Position (3) / L,
              VX => Velocity (1) / (L * N),
              VY => Velocity (2) / (L * N),
              VZ => Velocity (3) / (L * N));
   end To_Normalized;

   procedure To_Dimensional
      (State    : in  Normalized_State;
       System   : in  Threebody_System;
       Position : out Position_Vector;
       Velocity : out Velocity_Vector)
   is
      L : constant Real := Real (System.Distance);
      Mu_Total : constant Real := Real (System.Mu1) + Real (System.Mu2);
      N : constant Real := Sqrt (Mu_Total / (L * L * L));  -- Mean motion
   begin
      Position := (State.X * L, State.Y * L, State.Z * L);
      Velocity := (State.VX * L * N, State.VY * L * N, State.VZ * L * N);
   end To_Dimensional;

   function Normalized_Time_To_Seconds
      (T_Norm : Real;
       System : Threebody_System) return Time_Seconds
   is
      L : constant Real := Real (System.Distance);
      Mu_Total : constant Real := Real (System.Mu1) + Real (System.Mu2);
      N : constant Real := Sqrt (Mu_Total / (L * L * L));  -- Mean motion
   begin
      return Time_Seconds (T_Norm / N);
   end Normalized_Time_To_Seconds;

   ---------------------------------------------------------------------------
   -- State Transition Matrix Computation
   ---------------------------------------------------------------------------

   --  Compute the Jacobian matrix A of the CR3BP equations
   --  A is the 6x6 matrix dF/dX where F is the vector field [vx,vy,vz,ax,ay,az]
   procedure Compute_Jacobian
      (State : in  Normalized_State;
       Mu    : in  Real;
       A     : out Matrix_6x6)
   is
      X  : constant Real := State.X;
      Y  : constant Real := State.Y;
      Z  : constant Real := State.Z;

      R1_Val : constant Real := R1 (X, Y, Z, Mu);
      R2_Val : constant Real := R2 (X, Y, Z, Mu);
      R1_3   : constant Real := R1_Val ** 3;
      R2_3   : constant Real := R2_Val ** 3;
      R1_5   : constant Real := R1_Val ** 5;
      R2_5   : constant Real := R2_Val ** 5;

      DX1 : constant Real := X + Mu;           -- Distance to P1 in x
      DX2 : constant Real := X - (1.0 - Mu);   -- Distance to P2 in x

      --  Second partial derivatives of pseudo-potential
      Uxx, Uxy, Uxz, Uyy, Uyz, Uzz : Real;
   begin
      --  Compute second partials of the pseudo-potential Omega
      Uxx := 1.0 - (1.0 - Mu) / R1_3 - Mu / R2_3
             + 3.0 * (1.0 - Mu) * DX1 * DX1 / R1_5
             + 3.0 * Mu * DX2 * DX2 / R2_5;

      Uyy := 1.0 - (1.0 - Mu) / R1_3 - Mu / R2_3
             + 3.0 * (1.0 - Mu) * Y * Y / R1_5
             + 3.0 * Mu * Y * Y / R2_5;

      Uzz := -(1.0 - Mu) / R1_3 - Mu / R2_3
             + 3.0 * (1.0 - Mu) * Z * Z / R1_5
             + 3.0 * Mu * Z * Z / R2_5;

      Uxy := 3.0 * (1.0 - Mu) * DX1 * Y / R1_5
             + 3.0 * Mu * DX2 * Y / R2_5;

      Uxz := 3.0 * (1.0 - Mu) * DX1 * Z / R1_5
             + 3.0 * Mu * DX2 * Z / R2_5;

      Uyz := 3.0 * (1.0 - Mu) * Y * Z / R1_5
             + 3.0 * Mu * Y * Z / R2_5;

      --  Build the Jacobian matrix A = dF/dX
      --  State vector is [x, y, z, vx, vy, vz]
      --  F = [vx, vy, vz, ax, ay, az]
      --  where ax = 2*vy + Ux, ay = -2*vx + Uy, az = Uz

      --  Initialize to zero
      A := (others => (others => 0.0));

      --  dF(1..3)/d(x,y,z) = 0, dF(1..3)/d(vx,vy,vz) = I
      A (1, 4) := 1.0;  -- dx/dt depends on vx
      A (2, 5) := 1.0;  -- dy/dt depends on vy
      A (3, 6) := 1.0;  -- dz/dt depends on vz

      --  dF(4)/d(...) = d(ax)/d(...)
      A (4, 1) := Uxx;    -- d(ax)/dx
      A (4, 2) := Uxy;    -- d(ax)/dy
      A (4, 3) := Uxz;    -- d(ax)/dz
      A (4, 5) := 2.0;    -- d(ax)/dvy (Coriolis)

      --  dF(5)/d(...) = d(ay)/d(...)
      A (5, 1) := Uxy;    -- d(ay)/dx
      A (5, 2) := Uyy;    -- d(ay)/dy
      A (5, 3) := Uyz;    -- d(ay)/dz
      A (5, 4) := -2.0;   -- d(ay)/dvx (Coriolis)

      --  dF(6)/d(...) = d(az)/d(...)
      A (6, 1) := Uxz;    -- d(az)/dx
      A (6, 2) := Uyz;    -- d(az)/dy
      A (6, 3) := Uzz;    -- d(az)/dz
   end Compute_Jacobian;

   --  Matrix multiplication for 6x6 matrices
   function Matrix_Multiply (A, B : Matrix_6x6) return Matrix_6x6 is
      C : Matrix_6x6 := (others => (others => 0.0));
   begin
      for I in 1 .. 6 loop
         for J in 1 .. 6 loop
            for K in 1 .. 6 loop
               C (I, J) := C (I, J) + A (I, K) * B (K, J);
            end loop;
         end loop;
      end loop;
      return C;
   end Matrix_Multiply;

   --  Matrix-scalar multiplication
   function Matrix_Scale (S : Real; A : Matrix_6x6) return Matrix_6x6 is
      C : Matrix_6x6;
   begin
      for I in 1 .. 6 loop
         for J in 1 .. 6 loop
            C (I, J) := S * A (I, J);
         end loop;
      end loop;
      return C;
   end Matrix_Scale;

   --  Matrix addition
   function Matrix_Add (A, B : Matrix_6x6) return Matrix_6x6 is
      C : Matrix_6x6;
   begin
      for I in 1 .. 6 loop
         for J in 1 .. 6 loop
            C (I, J) := A (I, J) + B (I, J);
         end loop;
      end loop;
      return C;
   end Matrix_Add;

   function Propagate_With_STM
      (Initial_State : Normalized_State;
       Mu            : Real;
       T_Final       : Real;
       Step_Size     : Real := 0.001) return State_With_STM
   is
      --  Combined state: 6 for position/velocity + 36 for STM
      type Combined_State is array (1 .. 42) of Real;

      --  Initialize combined state
      Y : Combined_State;
      State : Normalized_State := Initial_State;
      STM : Matrix_6x6 := Identity_6x6;
      T : Real := 0.0;
      H : Real := Step_Size;

      procedure State_To_Combined (S : Normalized_State; M : Matrix_6x6;
                                    C : out Combined_State) is
         Idx : Natural := 7;
      begin
         C (1) := S.X;
         C (2) := S.Y;
         C (3) := S.Z;
         C (4) := S.VX;
         C (5) := S.VY;
         C (6) := S.VZ;
         for I in 1 .. 6 loop
            for J in 1 .. 6 loop
               C (Idx) := M (I, J);
               Idx := Idx + 1;
            end loop;
         end loop;
      end State_To_Combined;

      procedure Combined_To_State (C : Combined_State;
                                    S : out Normalized_State;
                                    M : out Matrix_6x6) is
         Idx : Natural := 7;
      begin
         S.X := C (1);
         S.Y := C (2);
         S.Z := C (3);
         S.VX := C (4);
         S.VY := C (5);
         S.VZ := C (6);
         for I in 1 .. 6 loop
            for J in 1 .. 6 loop
               M (I, J) := C (Idx);
               Idx := Idx + 1;
            end loop;
         end loop;
      end Combined_To_State;

      function Derivatives (C : Combined_State) return Combined_State is
         S : Normalized_State;
         M : Matrix_6x6;
         AX, AY, AZ : Real;
         A_Matrix : Matrix_6x6;
         M_Dot : Matrix_6x6;
         Result : Combined_State;
         Idx : Natural := 7;
      begin
         Combined_To_State (C, S, M);
         Compute_Acceleration (S, Mu, AX, AY, AZ);
         Compute_Jacobian (S, Mu, A_Matrix);

         --  STM derivative: dPhi/dt = A * Phi
         M_Dot := Matrix_Multiply (A_Matrix, M);

         Result (1) := S.VX;
         Result (2) := S.VY;
         Result (3) := S.VZ;
         Result (4) := AX;
         Result (5) := AY;
         Result (6) := AZ;
         for I in 1 .. 6 loop
            for J in 1 .. 6 loop
               Result (Idx) := M_Dot (I, J);
               Idx := Idx + 1;
            end loop;
         end loop;
         return Result;
      end Derivatives;

   begin
      State_To_Combined (State, STM, Y);

      while T < T_Final loop
         if T + H > T_Final then
            H := T_Final - T;
         end if;

         --  RK4 step for combined state
         declare
            K1, K2, K3, K4 : Combined_State;
            Y_Temp : Combined_State;
         begin
            K1 := Derivatives (Y);

            for I in 1 .. 42 loop
               Y_Temp (I) := Y (I) + 0.5 * H * K1 (I);
            end loop;
            K2 := Derivatives (Y_Temp);

            for I in 1 .. 42 loop
               Y_Temp (I) := Y (I) + 0.5 * H * K2 (I);
            end loop;
            K3 := Derivatives (Y_Temp);

            for I in 1 .. 42 loop
               Y_Temp (I) := Y (I) + H * K3 (I);
            end loop;
            K4 := Derivatives (Y_Temp);

            for I in 1 .. 42 loop
               Y (I) := Y (I) + H * (K1 (I) + 2.0 * K2 (I)
                                     + 2.0 * K3 (I) + K4 (I)) / 6.0;
            end loop;
         end;

         T := T + H;
         H := Step_Size;
      end loop;

      Combined_To_State (Y, State, STM);
      return (State => State, STM => STM);
   end Propagate_With_STM;

   function Compute_Monodromy
      (Initial_State : Normalized_State;
       Mu            : Real;
       Period        : Real;
       Step_Size     : Real := 0.0001) return Matrix_6x6
   is
      Result : constant State_With_STM :=
         Propagate_With_STM (Initial_State, Mu, Period, Step_Size);
   begin
      return Result.STM;
   end Compute_Monodromy;

   ---------------------------------------------------------------------------
   -- Floquet Analysis (Eigenvalue Computation)
   ---------------------------------------------------------------------------

   --  The monodromy matrix of the CR3BP flow is symplectic, so its
   --  characteristic polynomial is palindromic: with sigma = lambda +
   --  1/lambda the sextic reduces to the cubic
   --     sigma^3 - e1*sigma^2 + (e2 - 3)*sigma - (e3 - 2*e1) = 0
   --  where, via Newton's identities on the power sums p_k = tr(M^k):
   --     e1 = p1,  e2 = (p1^2 - p2)/2,  e3 = (p1^3 - 3*p1*p2 + 2*p3)/6.
   --  The cubic is solved in closed form and each sigma root is mapped
   --  back through lambda^2 - sigma*lambda + 1 = 0 to a reciprocal
   --  multiplier pair.
   function Analyze_Floquet (Monodromy : Matrix_6x6) return Floquet_Result is

      --  Validity thresholds; both residuals must pass for Valid = True
      --  (see the Floquet_Result.Valid comment in the spec)
      Symplectic_Defect_Tol : constant Real := 1.0e-6;
      --  Threshold on the Frobenius norm of Mp'*J*Mp - J, J being the
      --  standard symplectic form [[0, I3], [-I3, 0]], normalized by
      --  ||Mp||_F**2 so it is scale-independent (the defect grows
      --  quadratically with the matrix norm).  Mp is the monodromy matrix
      --  expressed in CANONICAL coordinates: the CR3BP rotating-frame flow
      --  is Hamiltonian in the momenta px = vx - y, py = vy + x, pz = vz,
      --  not in the velocities, so the [x,y,z,vx,vy,vz] STM must be
      --  similarity-transformed by T = [[I, 0], [A, I]] (A the Coriolis
      --  block) before the standard-J test applies.  An exact monodromy
      --  gives 0; RK4 integration error typically leaves ~1e-15.

      Trivial_Pair_Tol_Floor : constant Real := 1.0e-6;
      --  Floor of the threshold on min |sigma - 2|: a periodic-orbit
      --  monodromy carries an eigenvalue pair at exactly 1, i.e. one
      --  sigma root ~ 2.  The effective threshold is conditioning-aware:
      --  Real'Max (Floor, Cond_Amplification * Eps * (1 + p1**2)), see
      --  below.

      Cond_Amplification : constant Real := 32.0;
      --  Conditioning constant C_Cond for the trivial-pair threshold.
      --  The reduced-cubic coefficients are formed from the power sums
      --  p_k = tr(M^k); with p1 ~ lambda_max their absolute rounding
      --  error grows like Eps * p1**2 (p2 ~ p1**2, and the p1**3-order
      --  terms of e3 cancel down to O(p1)).  The sigma ~ 2 root is simple
      --  and well separated, so a coefficient perturbation of that size
      --  moves it by about the same amount (~1:1).  Observed residuals on
      --  exactly symplectic synthetic monodromies are ~2-3 * Eps * p1**2
      --  (e.g. ~5e-6 at lambda_max = 1e5, where Eps * p1**2 ~ 2.2e-6);
      --  32 provides an order-of-magnitude safety margin while still
      --  rejecting genuinely absent trivial pairs, which sit at
      --  |sigma - 2| = O(1).

      Condition_Warning_Level : constant Real := 1.0e-8;
      --  Eps * (1 + p1**2) above this level means the center/trivial
      --  sigma roots may be off by > 1e-8, hence the trivial multipliers
      --  (square-root amplification of the defective pair) by > 1e-4,
      --  even when Valid is True; reported via Condition_Warning.

      Result : Floquet_Result;

      function Magnitude (C : Complex_Number) return Real is
         (Sqrt (C.Re * C.Re + C.Im * C.Im));

      --  Signed real cube root ('**' requires a non-negative base)
      function Cbrt (X : Real) return Real is
         (if X >= 0.0 then X ** (1.0 / 3.0) else -((-X) ** (1.0 / 3.0)));

      --  Principal complex square root in polar form (hand-rolled: no
      --  complex-arithmetic package is instantiated in this library)
      function Complex_Sqrt (C : Complex_Number) return Complex_Number is
         R      : constant Real := Magnitude (C);
         Root_R : constant Real := Sqrt (R);
         Theta  : Real;
      begin
         if R = 0.0 then
            return (Re => 0.0, Im => 0.0);
         end if;
         Theta := Arctan (C.Im, C.Re);
         return (Re => Root_R * Cos (Theta / 2.0),
                 Im => Root_R * Sin (Theta / 2.0));
      end Complex_Sqrt;

      --  Power sums p_k = tr(M^k), k = 1 .. 3
      M_Sq : constant Matrix_6x6 := Matrix_Multiply (Monodromy, Monodromy);
      M_Cb : constant Matrix_6x6 := Matrix_Multiply (M_Sq, Monodromy);
      P1, P2, P3 : Real := 0.0;
      E1, E2, E3 : Real;

      --  Sigma roots of the reduced palindromic cubic
      Sigma : array (1 .. 3) of Complex_Number;

      --  Multiplier pairs: Pairs (K, 1) is the dominant member of pair K
      Pairs    : array (1 .. 3, 1 .. 2) of Complex_Number;
      Pair_Mag : array (1 .. 3) of Real;

      Defect_Norm : Real := 0.0;
      Min_Trivial : Real := Real'Last;
   begin
      Result.Monodromy := Monodromy;

      for I in 1 .. 6 loop
         P1 := P1 + Monodromy (I, I);
         P2 := P2 + M_Sq (I, I);
         P3 := P3 + M_Cb (I, I);
      end loop;

      --  Newton's identities
      E1 := P1;
      E2 := (P1 * P1 - P2) / 2.0;
      E3 := (P1 ** 3 - 3.0 * P1 * P2 + 2.0 * P3) / 6.0;

      --  Solve sigma^3 + CA*sigma^2 + CB*sigma + CC = 0 in closed form
      declare
         CA : constant Real := -E1;
         CB : constant Real := E2 - 3.0;
         CC : constant Real := -(E3 - 2.0 * E1);

         --  Depressed cubic t^3 + P*t + Q = 0 with sigma = t - CA/3
         Shift : constant Real := -CA / 3.0;
         P     : constant Real := CB - CA * CA / 3.0;
         Q     : constant Real := 2.0 * CA ** 3 / 27.0 - CA * CB / 3.0 + CC;
         Disc  : constant Real := (Q / 2.0) ** 2 + (P / 3.0) ** 3;
      begin
         if Disc > 0.0 then
            --  One real sigma root plus a complex-conjugate sigma pair
            --  (complex instability).  Compute the larger cube-root term
            --  first to avoid cancellation (U*V = -P/3).
            declare
               SqD  : constant Real := Sqrt (Disc);
               W    : constant Real := -Q / 2.0;
               U, V : Real;
            begin
               if W >= 0.0 then
                  U := Cbrt (W + SqD);
                  V := (if U /= 0.0 then -P / (3.0 * U) else 0.0);
               else
                  V := Cbrt (W - SqD);
                  U := (if V /= 0.0 then -P / (3.0 * V) else 0.0);
               end if;

               Sigma (1) := (Re => U + V + Shift, Im => 0.0);
               Sigma (2) := (Re => -(U + V) / 2.0 + Shift,
                             Im => Sqrt (3.0) / 2.0 * (U - V));
               Sigma (3) := (Re => Sigma (2).Re, Im => -Sigma (2).Im);
            end;
         elsif P >= -1.0e-30 then
            --  Disc <= 0 forces P <= 0; P ~ 0 then also means Q ~ 0,
            --  i.e. a (near-)triple real root
            declare
               T0 : constant Real := Cbrt (-Q);
            begin
               Sigma := (others => (Re => T0 + Shift, Im => 0.0));
            end;
         else
            --  Three real sigma roots (trigonometric form)
            declare
               Two_Pi  : constant Real := 2.0 * Ada.Numerics.Pi;
               Rho     : constant Real := 2.0 * Sqrt (-P / 3.0);
               Cos_Arg : Real := 3.0 * Q / (2.0 * P) * Sqrt (-3.0 / P);
               Phi     : Real;
            begin
               Cos_Arg := Real'Max (-1.0, Real'Min (1.0, Cos_Arg));
               Phi := Arccos (Cos_Arg);
               for K in 0 .. 2 loop
                  Sigma (K + 1) :=
                     (Re => Rho * Cos ((Phi - Two_Pi * Real (K)) / 3.0)
                            + Shift,
                      Im => 0.0);
               end loop;
            end;
         end if;
      end;

      --  Recover each multiplier pair from lambda^2 - sigma*lambda + 1 = 0
      for K in 1 .. 3 loop
         if Sigma (K).Im /= 0.0 then
            --  Complex sigma: complex-instability quadruple.  The two
            --  lambda roots for this sigma are mutually reciprocal; the
            --  conjugate sigma root supplies their complex conjugates.
            declare
               Disc_C : constant Complex_Number :=
                  (Re => Sigma (K).Re * Sigma (K).Re
                         - Sigma (K).Im * Sigma (K).Im - 4.0,
                   Im => 2.0 * Sigma (K).Re * Sigma (K).Im);
               S       : constant Complex_Number := Complex_Sqrt (Disc_C);
               L_Plus  : constant Complex_Number :=
                  (Re => (Sigma (K).Re + S.Re) / 2.0,
                   Im => (Sigma (K).Im + S.Im) / 2.0);
               L_Minus : constant Complex_Number :=
                  (Re => (Sigma (K).Re - S.Re) / 2.0,
                   Im => (Sigma (K).Im - S.Im) / 2.0);
            begin
               if Magnitude (L_Plus) >= Magnitude (L_Minus) then
                  Pairs (K, 1) := L_Plus;
                  Pairs (K, 2) := L_Minus;
               else
                  Pairs (K, 1) := L_Minus;
                  Pairs (K, 2) := L_Plus;
               end if;
            end;
         elsif abs (Sigma (K).Re) >= 2.0 then
            --  Real reciprocal pair (lambda, 1/lambda); take the root of
            --  larger magnitude first (numerically stable form)
            declare
               S_R      : constant Real := Sigma (K).Re;
               D        : constant Real := Sqrt (S_R * S_R - 4.0);
               Dominant : constant Real :=
                  (S_R + (if S_R >= 0.0 then D else -D)) / 2.0;
            begin
               Pairs (K, 1) := (Re => Dominant, Im => 0.0);
               Pairs (K, 2) := (Re => 1.0 / Dominant, Im => 0.0);
            end;
         else
            --  |sigma| < 2: unit-circle complex-conjugate pair
            declare
               S_R     : constant Real := Sigma (K).Re;
               Im_Part : constant Real := Sqrt (1.0 - S_R * S_R / 4.0);
            begin
               Pairs (K, 1) := (Re => S_R / 2.0, Im => Im_Part);
               Pairs (K, 2) := (Re => S_R / 2.0, Im => -Im_Part);
            end;
         end if;

         Pair_Mag (K) := Magnitude (Pairs (K, 1));

         --  Track the trivial-pair residual over the real sigma roots
         if Sigma (K).Im = 0.0
            and then abs (Sigma (K).Re - 2.0) < Min_Trivial
         then
            Min_Trivial := abs (Sigma (K).Re - 2.0);
         end if;
      end loop;

      --  Order the pairs by descending dominant magnitude so the dominant
      --  pair lands in Multipliers slots 1-2 (pairs stay adjacent:
      --  slots (1,2), (3,4), (5,6) are reciprocal pairs)
      for I in 1 .. 2 loop
         for J in 1 .. 3 - I loop
            if Pair_Mag (J) < Pair_Mag (J + 1) then
               declare
                  TM : constant Real := Pair_Mag (J);
                  T1 : constant Complex_Number := Pairs (J, 1);
                  T2 : constant Complex_Number := Pairs (J, 2);
               begin
                  Pair_Mag (J) := Pair_Mag (J + 1);
                  Pairs (J, 1) := Pairs (J + 1, 1);
                  Pairs (J, 2) := Pairs (J + 1, 2);
                  Pair_Mag (J + 1) := TM;
                  Pairs (J + 1, 1) := T1;
                  Pairs (J + 1, 2) := T2;
               end;
            end if;
         end loop;
      end loop;

      for K in 1 .. 3 loop
         Result.Multipliers (2 * K - 1) := Pairs (K, 1);
         Result.Multipliers (2 * K) := Pairs (K, 2);
      end loop;

      Result.Max_Multiplier := Pair_Mag (1);

      --  Periodic orbits in the CR3BP are marginally stable (all
      --  |lambda| = 1) or unstable (some |lambda| > 1)
      Result.Is_Stable := Result.Max_Multiplier <= 1.0 + 1.0e-6;

      --  Standard stability index nu = (lambda_max + 1/lambda_max)/2
      --  = sigma_max/2
      if Result.Max_Multiplier > 0.0 then
         Result.Stability_Index :=
            (Result.Max_Multiplier + 1.0 / Result.Max_Multiplier) / 2.0;
      else
         Result.Stability_Index := 0.0;
      end if;

      --  Symplectic defect: transform the monodromy to canonical
      --  coordinates (px = vx - y, py = vy + x, pz = vz) via
      --  Mp = T * M * T_inv, then evaluate ||Mp'*J*Mp - J||_F normalized
      --  by ||Mp||_F**2, using
      --  (Mp'*J*Mp)(I,J) = sum_k Mp(k,I)*Mp(k+3,J) - Mp(k+3,I)*Mp(k,J)
      declare
         T_Mat  : Matrix_6x6 := Identity_6x6;
         T_Inv  : Matrix_6x6 := Identity_6x6;
         MP     : Matrix_6x6;
         Norm_M : Real := 0.0;
         Val    : Real;
      begin
         T_Mat (4, 2) := -1.0;
         T_Mat (5, 1) := 1.0;
         T_Inv (4, 2) := 1.0;
         T_Inv (5, 1) := -1.0;
         MP := Matrix_Multiply (Matrix_Multiply (T_Mat, Monodromy), T_Inv);

         for I in 1 .. 6 loop
            for J in 1 .. 6 loop
               Val := 0.0;
               for K in 1 .. 3 loop
                  Val := Val + MP (K, I) * MP (K + 3, J)
                             - MP (K + 3, I) * MP (K, J);
               end loop;
               --  Subtract J(I,J)
               if J = I + 3 then
                  Val := Val - 1.0;
               elsif I = J + 3 then
                  Val := Val + 1.0;
               end if;
               Defect_Norm := Defect_Norm + Val * Val;
               Norm_M := Norm_M + MP (I, J) * MP (I, J);
            end loop;
         end loop;

         --  Norm_M >= 1 is guaranteed here for any nonzero matrix scale;
         --  guard anyway against a pathological all-zero input
         if Norm_M > 0.0 then
            Defect_Norm := Sqrt (Defect_Norm) / Norm_M;
         else
            Defect_Norm := Sqrt (Defect_Norm);
         end if;
      end;

      --  Validity and conditioning report.  The symplectic-defect check is
      --  NOT relaxed with conditioning; only the trivial-pair residual
      --  threshold scales with the coefficient rounding error Eps * p1**2
      --  (see Cond_Amplification above).
      declare
         Eps         : constant Real := Real'Model_Epsilon;
         Cond_Scale  : constant Real := Eps * (1.0 + P1 ** 2);
         Tol_Trivial : constant Real :=
            Real'Max (Trivial_Pair_Tol_Floor,
                      Cond_Amplification * Cond_Scale);
      begin
         Result.Condition_Warning := Cond_Scale > Condition_Warning_Level;
         Result.Valid := Defect_Norm <= Symplectic_Defect_Tol
                         and then Min_Trivial <= Tol_Trivial;
      end;

      return Result;
   end Analyze_Floquet;

   ---------------------------------------------------------------------------
   -- Periodic Orbit Finders
   ---------------------------------------------------------------------------

   function Find_Lyapunov_Orbit
      (System          : Threebody_System;
       Point           : Lagrange_Point;
       Amplitude       : Real;
       Initial_Guess_Y : Real := 0.0;
       Tolerance       : Real := 1.0e-10;
       Max_Iterations  : Positive := 50) return Periodic_Orbit
   is
      Mu : constant Real := System.Mass_Ratio;
      LP : constant Lagrange_Result := Compute_Lagrange_Point (System, Point);
      Result : Periodic_Orbit;

      --  Initial guess: start at x = LP.X + Amplitude, y = z = 0
      --  with vy chosen to give approximately periodic motion
      X0 : constant Real := LP.X + Amplitude;
      Y0 : constant Real := 0.0;
      Z0 : constant Real := 0.0;
      VX0 : constant Real := 0.0;
      VY0 : Real;
      VZ0 : constant Real := 0.0;

      State : Normalized_State;
      Half_Period : Real;
      Converged : Boolean := False;
      Iter : Natural := 0;
   begin
      --  Initial y-velocity guess
      if Initial_Guess_Y /= 0.0 then
         VY0 := Initial_Guess_Y;
      else
         case Point is
            when L1 | L2 =>
               --  Linearized in-plane dynamics about the collinear point:
               --  with c2 the second Legendre coefficient, the planar
               --  frequency Nu solves
               --     Nu^4 + (c2 - 2)*Nu^2 - (c2 - 1)*(1 + 2*c2) = 0
               --  and the amplitude ratio is Kappa = (Nu^2+1+2c2)/(2Nu);
               --  a periodic solution displaced +Amplitude in x then needs
               --  vy0 = -Kappa*Nu*Amplitude.  (The previous rough guess of
               --  -2*Amplitude was far enough off that the Newton
               --  corrector oscillated for small amplitudes.)
               declare
                  Gamma_L : constant Real := abs (LP.X - (1.0 - Mu));
                  Sign_L  : constant Real :=
                     (if Point = L1 then 1.0 else -1.0);
                  G3      : constant Real := Gamma_L ** 3;
                  C2      : constant Real :=
                     (Mu + Sign_L * (1.0 - Mu) * G3
                           / ((1.0 - Sign_L * Gamma_L) ** 3)) / G3;
                  A_Coef  : constant Real := C2 - 2.0;
                  B_Coef  : constant Real :=
                     -(C2 - 1.0) * (1.0 + 2.0 * C2);
                  Disc    : constant Real := A_Coef * A_Coef - 4.0 * B_Coef;
                  Nu_Sq   : constant Real :=
                     (if Disc >= 0.0
                      then (-A_Coef + Sqrt (Disc)) / 2.0
                      else 1.0);
                  Nu      : constant Real :=
                     (if Nu_Sq > 0.0 then Sqrt (Nu_Sq) else 1.0);
                  Kappa   : constant Real :=
                     (Nu * Nu + 1.0 + 2.0 * C2) / (2.0 * Nu);
               begin
                  VY0 := -Kappa * Nu * Amplitude;
               end;

            when others =>
               --  L3: keep the rough approximation
               VY0 := -2.0 * Amplitude;
         end case;
      end if;

      State := (X => X0, Y => Y0, Z => Z0, VX => VX0, VY => VY0, VZ => VZ0);

      --  Estimate initial half-period (propagate until y crosses zero going negative)
      Half_Period := 3.14159 / 2.0;  -- Initial guess ~pi/2 in normalized time

      --  Differential correction loop
      for I in 1 .. Max_Iterations loop
         Iter := I;

         --  Propagate until y = 0 crossing (half period)
         declare
            T : Real := 0.0;
            H : constant Real := 0.001;
            Prev_State : Normalized_State := State;
            Current : Normalized_State := State;
            Crossed : Boolean := False;
         begin
            while T < 10.0 loop  -- Maximum time limit
               Prev_State := Current;
               Current := Propagate (Current, Mu, H, H, RK4);
               T := T + H;

               --  Check for y = 0 crossing (going from positive to negative
               --  or vice versa).  Strict sign requirement on Prev_State.Y:
               --  the orbit STARTS at y = 0 exactly, and a non-strict test
               --  fired on the very first step, yielding a bogus
               --  near-zero "half period"
               if (Prev_State.Y > 0.0 and Current.Y <= 0.0) or
                  (Prev_State.Y < 0.0 and Current.Y >= 0.0)
               then
                  --  Refine crossing point with bisection
                  declare
                     T_Low : Real := T - H;
                     T_High : Real := T;
                     T_Mid : Real;
                     S_Test : Normalized_State;
                  begin
                     for Bisect in 1 .. 30 loop
                        T_Mid := (T_Low + T_High) / 2.0;
                        S_Test := Propagate (State, Mu, T_Mid, 0.0001, RK4);
                        if (Prev_State.Y >= 0.0 and S_Test.Y >= 0.0) or
                           (Prev_State.Y < 0.0 and S_Test.Y < 0.0)
                        then
                           T_Low := T_Mid;
                        else
                           T_High := T_Mid;
                        end if;
                        if abs (S_Test.Y) < 1.0e-14 then
                           exit;
                        end if;
                     end loop;
                     Half_Period := T_Mid;
                     Current := Propagate (State, Mu, Half_Period, 0.0001, RK4);
                  end;
                  Crossed := True;
                  exit;
               end if;
            end loop;

            if not Crossed then
               --  Didn't find crossing, use propagated state
               Half_Period := T;
            end if;

            --  At half period, for a symmetric Lyapunov orbit we need:
            --  y = 0 (achieved by crossing detection)
            --  vx = 0 (periodicity condition)

            --  Check convergence (Half_Period already holds the refined
            --  crossing time from the bisection above; do not overwrite it
            --  with the coarse step time T)
            if abs (Current.VX) < Tolerance and abs (Current.Y) < Tolerance then
               Converged := True;
               exit;
            end if;

            --  Differential correction using STM
            declare
               Result_STM : constant State_With_STM :=
                  Propagate_With_STM (State, Mu, Half_Period, 0.0001);
               Phi : constant Matrix_6x6 := Result_STM.STM;
               AX, AY, AZ : Real;

               --  Correction equations for y(T/2) = 0, vx(T/2) = 0
               --  Variables to adjust: vy0, T/2
               --  dy = Phi(2,5)*dvy0 + vy*dT
               --  dvx = Phi(4,5)*dvy0 + ax*dT

               Det, DVY0, DT : Real;
            begin
               Compute_Acceleration (Result_STM.State, Mu, AX, AY, AZ);

               --  2x2 system: [Phi25, vy; Phi45, ax] * [dvy0; dT] = [-y; -vx]
               Det := Phi (2, 5) * AX - Phi (4, 5) * Result_STM.State.VY;

               if abs (Det) > 1.0e-15 then
                  DVY0 := (-Result_STM.State.Y * AX + Result_STM.State.VX * Result_STM.State.VY) / Det;
                  DT := (-Phi (2, 5) * Result_STM.State.VX + Phi (4, 5) * Result_STM.State.Y) / Det;

                  --  Apply corrections
                  State.VY := State.VY + DVY0;
                  Half_Period := Half_Period + DT;

                  --  Limit step size for stability
                  if abs (DVY0) > 0.1 then
                     State.VY := State.VY - DVY0 + 0.1 * (DVY0 / abs (DVY0));
                  end if;
               end if;
            end;
         end;
      end loop;

      --  Populate result
      Result.Orbit_Type := Lyapunov;
      Result.Initial_State := State;
      Result.Period := 2.0 * Half_Period;
      Result.Jacobi := Jacobi_Constant (State, Mu);
      Result.Amplitude_X := Amplitude;
      Result.Amplitude_Z := 0.0;
      Result.Converged := Converged;
      Result.Iterations_Used := Iter;

      return Result;
   end Find_Lyapunov_Orbit;

   function Richardson_Halo_Guess
      (System      : Threebody_System;
       Point       : Lagrange_Point;
       Amplitude_Z : Real;
       Family      : Periodic_Orbit_Type := Halo_Northern) return Normalized_State
   is
      Mu : constant Real := System.Mass_Ratio;
      LP : constant Lagrange_Result := Compute_Lagrange_Point (System, Point);

      --  Richardson third-order approximation coefficients
      --  Reference: Richardson (1980), "Analytic Construction of Periodic Orbits
      --  about the Collinear Points"

      --  Distance from smaller primary to L-point
      Gamma : constant Real := abs (LP.X - (1.0 - Mu));
      Gamma_2 : constant Real := Gamma * Gamma;
      Gamma_3 : constant Real := Gamma_2 * Gamma;

      --  Sign factor: +1 for L1, -1 for L2
      Sign_L : constant Real := (if Point = L1 then 1.0 else -1.0);

      --  Legendre polynomial coefficients (c2, c3, c4)
      C2 : Real;
      C3 : Real;
      C4 : Real;

      --  Frequencies
      Lambda : Real;
      K : Real;

      --  Initial state components
      X0, Y0, Z0 : Real;
      VX0, VY0, VZ0 : Real;
   begin
      --  Compute cn coefficients
      C2 := (Mu + Sign_L * (1.0 - Mu) * Gamma_3 / ((1.0 - Sign_L * Gamma) ** 3)) / Gamma_3;
      C3 := (Sign_L * Mu + (1.0 - Mu) * Gamma ** 4 / ((1.0 - Sign_L * Gamma) ** 4)) / Gamma ** 4;
      C4 := (Mu + Sign_L * (1.0 - Mu) * Gamma ** 5 / ((1.0 - Sign_L * Gamma) ** 5)) / Gamma ** 5;

      --  Compute in-plane frequency (eigenvalue related)
      --  lambda^4 + (c2 - 2)*lambda^2 - (c2 - 1)*(1 + 2*c2) = 0
      declare
         A_Coef : constant Real := C2 - 2.0;
         B_Coef : constant Real := -(C2 - 1.0) * (1.0 + 2.0 * C2);
         Discriminant : constant Real := A_Coef * A_Coef - 4.0 * B_Coef;
         Lambda_Sq : Real;
      begin
         if Discriminant >= 0.0 then
            Lambda_Sq := (-A_Coef + Sqrt (Discriminant)) / 2.0;
            if Lambda_Sq > 0.0 then
               Lambda := Sqrt (Lambda_Sq);
            else
               Lambda := 1.0;  -- Default fallback
            end if;
         else
            Lambda := 1.0;  -- Default fallback
         end if;
      end;

      --  Compute K factor (ratio of in-plane to out-of-plane amplitude)
      K := (Lambda * Lambda + 1.0 + 2.0 * C2) / (2.0 * Lambda);

      --  Richardson third-order approximation
      --  The z-amplitude Az is the input, we derive Ax from Az
      declare
         Az : constant Real := Amplitude_Z / Real (System.Distance);  -- Normalized
         Delta_Val : constant Real := Lambda * Lambda - C2;

         --  Third-order coefficient relationships (simplified)
         A21 : constant Real := 3.0 * C3 * (K * K - 2.0) / (4.0 * (1.0 + 2.0 * C2));
         A22 : constant Real := 3.0 * C3 / (4.0 * (1.0 + 2.0 * C2));
         A31 : constant Real := -9.0 * Lambda / (4.0 * Delta_Val) *
               (C3 * (K * A21 - 2.0 * A22) - C4 * K * K / 2.0);

         L1_Coef : Real;
         L2_Coef : Real;
         Ax : Real;
      begin
         --  Amplitude relationship: Ax^2 = -L2/L1 * Az^2 (approximately)
         --  For halo orbits, Ax ~ k * Az where k depends on mass ratio and point
         L1_Coef := A31 + 3.0 / 8.0;
         L2_Coef := 3.0 * Lambda / (4.0 * Delta_Val);

         if abs (L1_Coef) > 1.0e-15 and L2_Coef / L1_Coef > 0.0 then
            Ax := Sqrt (L2_Coef / L1_Coef) * Az;
         else
            --  Use approximate relationship Ax ~ Az for small amplitudes
            Ax := Az;
         end if;

         --  Third-order approximation at t=0 (y=0 crossing)
         --  For northern family: z starts positive
         --  For southern family: z starts negative
         declare
            M : constant Real := (if Family = Halo_Northern then 1.0 else 3.0);
            --  Phase angle for initial condition (at y=0)
            Phi_Z : constant Real := M * 3.14159 / 2.0;
            Tau : constant Real := 0.0;  -- Initial time

            --  Compute position and velocity components
            A21_Term : constant Real := A21 * Ax * Ax;
            A22_Term : constant Real := A22 * Az * Az;
         begin
            --  Position (normalized, centered on Lagrange point)
            X0 := LP.X + Gamma * (Ax * Cos (Lambda * Tau) + A21_Term - A22_Term);
            Y0 := Gamma * K * Ax * Sin (Lambda * Tau);
            Z0 := Gamma * Az * Sin (Lambda * Tau + Phi_Z);

            --  Velocity
            VX0 := Gamma * Lambda * (-Ax * Sin (Lambda * Tau));
            VY0 := Gamma * Lambda * K * Ax * Cos (Lambda * Tau);
            VZ0 := Gamma * Lambda * Az * Cos (Lambda * Tau + Phi_Z);

            --  Adjust for northern vs southern
            if Family = Halo_Southern then
               Z0 := -Z0;
               VZ0 := -VZ0;
            end if;
         end;
      end;

      return (X => X0, Y => Y0, Z => Z0, VX => VX0, VY => VY0, VZ => VZ0);
   end Richardson_Halo_Guess;

   function Find_Halo_Orbit
      (System         : Threebody_System;
       Point          : Lagrange_Point;
       Amplitude_Z    : Real;
       Family         : Periodic_Orbit_Type := Halo_Northern;
       Tolerance      : Real := 1.0e-10;
       Max_Iterations : Positive := 50) return Periodic_Orbit
   is
      Mu : constant Real := System.Mass_Ratio;
      Result : Periodic_Orbit;

      --  Start with Richardson approximation
      State : Normalized_State := Richardson_Halo_Guess (System, Point, Amplitude_Z, Family);

      Half_Period : Real := 3.14159;  -- Initial guess
      Converged : Boolean := False;
      Iter : Natural := 0;
   begin
      --  Differential correction loop for Halo orbit
      --  Target: at half period, y = 0, vx = 0, vz = 0 (perpendicular crossing)
      for I in 1 .. Max_Iterations loop
         Iter := I;

         --  Propagate until y = 0 crossing
         declare
            T : Real := 0.0;
            H : constant Real := 0.001;
            Prev_State : Normalized_State := State;
            Current : Normalized_State := State;
         begin
            while T < 15.0 loop
               Prev_State := Current;
               Current := Propagate (Current, Mu, H, H, RK4);
               T := T + H;

               --  Check for y = 0 crossing
               if Prev_State.Y * Current.Y < 0.0 then
                  --  Refine with bisection
                  declare
                     T_Low : Real := T - H;
                     T_High : Real := T;
                     T_Mid : Real;
                     S_Test : Normalized_State;
                  begin
                     for Bisect in 1 .. 30 loop
                        T_Mid := (T_Low + T_High) / 2.0;
                        S_Test := Propagate (State, Mu, T_Mid, 0.0001, RK4);
                        if Prev_State.Y * S_Test.Y >= 0.0 then
                           T_Low := T_Mid;
                        else
                           T_High := T_Mid;
                        end if;
                     end loop;
                     Half_Period := T_Mid;
                     Current := Propagate (State, Mu, Half_Period, 0.0001, RK4);
                  end;
                  exit;
               end if;
            end loop;

            --  Check convergence: y ~ 0, vx ~ 0, vz ~ 0
            if abs (Current.Y) < Tolerance and
               abs (Current.VX) < Tolerance and
               abs (Current.VZ) < Tolerance
            then
               Converged := True;
               exit;
            end if;

            --  Differential correction using STM
            declare
               Result_STM : constant State_With_STM :=
                  Propagate_With_STM (State, Mu, Half_Period, 0.0001);
               Phi : constant Matrix_6x6 := Result_STM.STM;
               AX_Val, AY_Val, AZ_Val : Real;

               --  For Halo orbit, we adjust: x0, vy0, vz0, T/2
               --  Targets: y(T/2)=0, vx(T/2)=0, vz(T/2)=0

               --  Simplified single-shooting correction
               --  Using pseudo-inverse approach
               Err_Y : constant Real := Result_STM.State.Y;
               Err_VX : constant Real := Result_STM.State.VX;
               Err_VZ : constant Real := Result_STM.State.VZ;
            begin
               Compute_Acceleration (Result_STM.State, Mu, AX_Val, AY_Val, AZ_Val);

               --  3x3 correction matrix for [dx0, dvy0, dT]
               --  targeting [y, vx, vz] = 0
               declare
                  --  Partial derivatives
                  Phi_21 : constant Real := Phi (2, 1);  -- dy/dx0
                  Phi_25 : constant Real := Phi (2, 5);  -- dy/dvy0
                  Phi_41 : constant Real := Phi (4, 1);  -- dvx/dx0
                  Phi_45 : constant Real := Phi (4, 5);  -- dvx/dvy0
                  Phi_61 : constant Real := Phi (6, 1);  -- dvz/dx0
                  Phi_65 : constant Real := Phi (6, 5);  -- dvz/dvy0
                  VY_F : constant Real := Result_STM.State.VY;

                  --  Include time derivatives
                  DY_DT : constant Real := VY_F;
                  DVX_DT : constant Real := AX_Val;
                  DVZ_DT : constant Real := AZ_Val;

                  --  3x3 matrix M and solve M * [dx0, dvy0, dT]^T = -[y, vx, vz]^T
                  --  Using simple Gauss elimination
                  M11 : Real := Phi_21;
                  M12 : Real := Phi_25;
                  M13 : Real := DY_DT;
                  M21 : Real := Phi_41;
                  M22 : Real := Phi_45;
                  M23 : Real := DVX_DT;
                  M31 : Real := Phi_61;
                  M32 : Real := Phi_65;
                  M33 : Real := DVZ_DT;
                  B1 : Real := -Err_Y;
                  B2 : Real := -Err_VX;
                  B3 : Real := -Err_VZ;
                  Factor : Real;
                  DX0, DVY0, DT : Real;
               begin
                  --  Forward elimination
                  if abs (M11) > 1.0e-15 then
                     Factor := M21 / M11;
                     M22 := M22 - Factor * M12;
                     M23 := M23 - Factor * M13;
                     B2 := B2 - Factor * B1;

                     Factor := M31 / M11;
                     M32 := M32 - Factor * M12;
                     M33 := M33 - Factor * M13;
                     B3 := B3 - Factor * B1;
                  end if;

                  if abs (M22) > 1.0e-15 then
                     Factor := M32 / M22;
                     M33 := M33 - Factor * M23;
                     B3 := B3 - Factor * B2;
                  end if;

                  --  Back substitution
                  if abs (M33) > 1.0e-15 then
                     DT := B3 / M33;
                  else
                     DT := 0.0;
                  end if;

                  if abs (M22) > 1.0e-15 then
                     DVY0 := (B2 - M23 * DT) / M22;
                  else
                     DVY0 := 0.0;
                  end if;

                  if abs (M11) > 1.0e-15 then
                     DX0 := (B1 - M12 * DVY0 - M13 * DT) / M11;
                  else
                     DX0 := 0.0;
                  end if;

                  --  Limit corrections for stability
                  if abs (DX0) > 0.01 then
                     DX0 := 0.01 * (DX0 / abs (DX0));
                  end if;
                  if abs (DVY0) > 0.1 then
                     DVY0 := 0.1 * (DVY0 / abs (DVY0));
                  end if;
                  if abs (DT) > 1.0 then
                     DT := 1.0 * (DT / abs (DT));
                  end if;

                  --  Apply corrections
                  State.X := State.X + DX0;
                  State.VY := State.VY + DVY0;
                  Half_Period := Half_Period + DT;

                  --  Keep the half period physically meaningful: when far
                  --  from a solution the corrector could otherwise walk it
                  --  negative, producing a nonsensical negative Period
                  if Half_Period < 0.1 then
                     Half_Period := 0.1;
                  end if;
               end;
            end;
         end;
      end loop;

      --  Populate result
      Result.Orbit_Type := Family;
      Result.Initial_State := State;
      Result.Period := 2.0 * Half_Period;
      Result.Jacobi := Jacobi_Constant (State, Mu);
      Result.Amplitude_X := abs (State.X - Compute_Lagrange_Point (System, Point).X);
      Result.Amplitude_Z := abs (State.Z);
      Result.Converged := Converged;
      Result.Iterations_Used := Iter;

      return Result;
   end Find_Halo_Orbit;

   function Generate_Orbit_Family
      (System        : Threebody_System;
       Point         : Lagrange_Point;
       Orbit_Type    : Periodic_Orbit_Type;
       Amp_Start     : Real;
       Amp_End       : Real;
       Num_Orbits    : Positive;
       Tolerance     : Real := 1.0e-10) return Periodic_Orbit_Array
   is
      Result : Periodic_Orbit_Array (1 .. Num_Orbits);
      Amp_Step : constant Real := (Amp_End - Amp_Start) / Real (Num_Orbits - 1);
      Current_Amp : Real := Amp_Start;
   begin
      for I in 1 .. Num_Orbits loop
         case Orbit_Type is
            when Lyapunov =>
               Result (I) := Find_Lyapunov_Orbit
                  (System, Point, Current_Amp, Tolerance => Tolerance);

            when Halo_Northern | Halo_Southern =>
               Result (I) := Find_Halo_Orbit
                  (System, Point, Current_Amp, Orbit_Type, Tolerance);
         end case;

         Current_Amp := Current_Amp + Amp_Step;
      end loop;

      return Result;
   end Generate_Orbit_Family;

end Hale_Orbital.Threebody;
