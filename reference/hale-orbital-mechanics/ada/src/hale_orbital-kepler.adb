-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Kepler's Equation Solvers Body
-------------------------------------------------------------------------------

with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;   use Hale_Orbital.Vectors;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;
with Hale_Orbital.Elements;  use Hale_Orbital.Elements;
with Hale_Orbital.Stumpff;   use Hale_Orbital.Stumpff;

package body Hale_Orbital.Kepler
   with SPARK_Mode => Off  --  Body uses generic instantiation
is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   ---------------------------------------------------------------------------
   -- Kepler's Equation Solvers
   ---------------------------------------------------------------------------

   function Solve_Kepler_Elliptic (Mean_Anomaly : Angle_Radians;
                                   Eccentricity : Real;
                                   Tolerance    : Real := Default_Tolerance;
                                   Max_Iter     : Positive := Default_Max_Iterations) return Angle_Radians is
      M : constant Real := Real (Mean_Anomaly);
      E_Anom : Real;
      F, F_Prime, Delta_Val : Real;
      Iter : Natural := 0;
   begin
      if Eccentricity < 0.0 or Eccentricity >= 1.0 then
         raise Invalid_Orbit with "Elliptic Kepler requires 0 <= e < 1";
      end if;

      --  Initial guess: use mean anomaly for low e, pi for high e (ISS-032)
      if Eccentricity < High_Eccentricity_Threshold then
         E_Anom := M;
      else
         E_Anom := Pi;
      end if;

      --  Newton-Raphson iteration
      loop
         pragma Loop_Invariant (Iter < Max_Iter);
         --  Invariant: iteration count bounded, convergence expected

         F := E_Anom - Eccentricity * Sin (E_Anom) - M;
         F_Prime := 1.0 - Eccentricity * Cos (E_Anom);

         if abs (F_Prime) < 1.0e-15 then
            raise Convergence_Error with "Derivative too small in Kepler solver";
         end if;

         Delta_Val := F / F_Prime;
         E_Anom := E_Anom - Delta_Val;
         Iter := Iter + 1;

         exit when abs (Delta_Val) < Tolerance;

         if Iter >= Max_Iter then
            raise Convergence_Error with "Kepler solver failed to converge";
         end if;
      end loop;

      return Angle_Radians (E_Anom);
   end Solve_Kepler_Elliptic;

   function Solve_Kepler_Hyperbolic (Mean_Anomaly : Real;
                                     Eccentricity : Real;
                                     Tolerance    : Real := Default_Tolerance;
                                     Max_Iter     : Positive := Default_Max_Iterations) return Real is
      M : constant Real := Mean_Anomaly;
      H : Real;
      Sinh_H, Cosh_H : Real;
      F, F_Prime, Delta_Val : Real;
      Iter : Natural := 0;
   begin
      if Eccentricity <= 1.0 then
         raise Invalid_Orbit with "Hyperbolic Kepler requires e > 1";
      end if;

      --  Initial guess
      if abs (M) < 1.0 then
         H := M;
      else
         H := Log (2.0 * abs (M) / Eccentricity + 1.8);
         if M < 0.0 then
            H := -H;
         end if;
      end if;

      --  Newton-Raphson iteration
      loop
         pragma Loop_Invariant (Iter < Max_Iter);
         --  Invariant: iteration count bounded, convergence expected

         Sinh_H := (Exp (H) - Exp (-H)) / 2.0;
         Cosh_H := (Exp (H) + Exp (-H)) / 2.0;

         F := Eccentricity * Sinh_H - H - M;
         F_Prime := Eccentricity * Cosh_H - 1.0;

         if abs (F_Prime) < 1.0e-15 then
            raise Convergence_Error with "Derivative too small in hyperbolic Kepler";
         end if;

         Delta_Val := F / F_Prime;
         H := H - Delta_Val;
         Iter := Iter + 1;

         exit when abs (Delta_Val) < Tolerance;

         if Iter >= Max_Iter then
            raise Convergence_Error with "Hyperbolic Kepler solver failed to converge";
         end if;
      end loop;

      return H;
   end Solve_Kepler_Hyperbolic;

   function Solve_Kepler_Parabolic (Mean_Anomaly : Real;
                                    Tolerance    : Real := Default_Tolerance) return Angle_Radians is
      --  Barker's equation: tan(nu/2) = D, M = D + D^3/3
      --  Solve cubic for D
      pragma Unreferenced (Tolerance);  -- Cardano closed-form; no iteration
      M : constant Real := Mean_Anomaly;
      W, D : Real;
   begin
      --  Use Cardano's formula for the cubic
      W := 1.5 * M;
      W := (W + Sqrt (W * W + 1.0)) ** (1.0 / 3.0);
      D := W - 1.0 / W;

      --  True anomaly from D = tan(nu/2)
      return Angle_Radians (2.0 * Arctan (D));
   end Solve_Kepler_Parabolic;

   ---------------------------------------------------------------------------
   -- Universal Variable Formulation
   -- (Stumpff functions are now in Hale_Orbital.Stumpff module)
   ---------------------------------------------------------------------------

   function Solve_Kepler_Universal (Dt           : Time_Seconds;
                                    R0           : Distance_Km;
                                    Vr0          : Velocity_Km_S;
                                    A            : Distance_Km;
                                    Mu           : Gravitational_Parameter;
                                    Tolerance    : Real := Default_Tolerance;
                                    Max_Iter     : Positive := Default_Max_Iterations) return Real is
      --  Universal variable formulation
      --  Solves: sqrt(mu) * dt = r0 * vr0/sqrt(mu) * chi^2 * C(alpha*chi^2)
      --                        + (1 - alpha*r0) * chi^3 * S(alpha*chi^2)
      --                        + r0 * chi
      --  where alpha = 1/a

      Alpha : constant Real := 1.0 / Real (A);
      Mu_Val : constant Real := Real (Mu);
      Sqrt_Mu : constant Real := Sqrt (Mu_Val);
      Dt_Val : constant Real := Real (Dt);
      R0_Val : constant Real := Real (R0);
      Vr0_Val : constant Real := Real (Vr0);

      Chi : Real;
      Chi_Sq, Z : Real;
      C_Z, S_Z : Real;
      F, F_Prime : Real;
      R : Real;
      Delta_Val : Real;
      Iter : Natural := 0;
   begin
      --  Initial guess
      Chi := Sqrt_Mu * abs (Dt_Val) / R0_Val;

      --  Newton-Raphson iteration
      loop
         pragma Loop_Invariant (Iter < Max_Iter);
         --  Invariant: iteration count bounded, convergence expected

         Chi_Sq := Chi * Chi;
         Z := Alpha * Chi_Sq;

         C_Z := C (Z);
         S_Z := S (Z);

         --  Current radius
         R := Chi_Sq * C_Z + (R0_Val * Vr0_Val / Sqrt_Mu) * Chi * (1.0 - Z * S_Z) +
              R0_Val * (1.0 - Z * C_Z);

         --  Function value (should be zero)
         F := (R0_Val * Vr0_Val / Sqrt_Mu) * Chi_Sq * C_Z +
              (1.0 - Alpha * R0_Val) * Chi_Sq * Chi * S_Z +
              R0_Val * Chi - Sqrt_Mu * Dt_Val;

         --  Derivative
         F_Prime := R;

         if abs (F_Prime) < 1.0e-15 then
            raise Convergence_Error with "Universal Kepler derivative too small";
         end if;

         Delta_Val := F / F_Prime;
         Chi := Chi - Delta_Val;
         Iter := Iter + 1;

         exit when abs (Delta_Val) < Tolerance;

         if Iter >= Max_Iter then
            raise Convergence_Error with "Universal Kepler solver failed to converge";
         end if;
      end loop;

      return Chi;
   end Solve_Kepler_Universal;

   ---------------------------------------------------------------------------
   -- Time of Flight
   ---------------------------------------------------------------------------

   function Time_Of_Flight_Elliptic (Nu1 : Angle_Radians;
                                     Nu2 : Angle_Radians;
                                     A   : Distance_Km;
                                     E   : Real;
                                     Mu  : Gravitational_Parameter) return Time_Seconds is
      E1, E2 : Angle_Radians;
      M1, M2 : Angle_Radians;
      N : Real;
      Dt : Real;
   begin
      --  Check for non-elliptic orbit (ISS-033: use threshold for consistency)
      if E > 1.0 - Parabolic_Threshold then
         raise Invalid_Orbit with "Elliptic time of flight requires e < 1";
      end if;

      --  Convert to eccentric anomalies
      E1 := True_To_Eccentric_Anomaly (Nu1, E);
      E2 := True_To_Eccentric_Anomaly (Nu2, E);

      --  Convert to mean anomalies
      M1 := Eccentric_To_Mean_Anomaly (E1, E);
      M2 := Eccentric_To_Mean_Anomaly (E2, E);

      --  Mean motion
      N := Mean_Motion (A, Mu);

      --  Time of flight
      Dt := (Real (M2) - Real (M1)) / N;

      --  Handle negative times (went past 2*pi)
      if Dt < 0.0 then
         Dt := Dt + Two_Pi / N;
      end if;

      return Time_Seconds (Dt);
   end Time_Of_Flight_Elliptic;

   function Time_Of_Flight_Hyperbolic (Nu1 : Angle_Radians;
                                       Nu2 : Angle_Radians;
                                       A   : Distance_Km;
                                       E   : Real;
                                       Mu  : Gravitational_Parameter) return Time_Seconds is
      H1, H2 : Real;
      M1, M2 : Real;
      N : Real;
      Dt : Real;
      A_Val : constant Real := abs (Real (A));
   begin
      if E <= 1.0 then
         raise Invalid_Orbit with "Hyperbolic time of flight requires e > 1";
      end if;

      --  Convert to hyperbolic anomalies
      H1 := True_To_Hyperbolic_Anomaly (Nu1, E);
      H2 := True_To_Hyperbolic_Anomaly (Nu2, E);

      --  Convert to mean anomalies
      M1 := Hyperbolic_To_Mean_Anomaly (H1, E);
      M2 := Hyperbolic_To_Mean_Anomaly (H2, E);

      --  Hyperbolic "mean motion"
      N := Sqrt (Real (Mu) / (A_Val * A_Val * A_Val));

      --  Time of flight
      Dt := (M2 - M1) / N;

      return Time_Seconds (Dt);
   end Time_Of_Flight_Hyperbolic;

   ----------------------------
   -- Time_Of_Flight_Parabolic
   ----------------------------

   --  Barker's equation:  t - t_p = (1/2) * sqrt(p^3 / mu) * (D + D^3 / 3)
   --  with D = tan(nu/2).  See Vallado, eqs. 2-66, 2-67.  Pure closed-form;
   --  no iteration required.
   function Time_Of_Flight_Parabolic (Nu1 : Angle_Radians;
                                      Nu2 : Angle_Radians;
                                      P   : Distance_Km;
                                      Mu  : Gravitational_Parameter) return Time_Seconds is
      P_Val  : constant Real := Real (P);
      Mu_Val : constant Real := Real (Mu);
      D1     : constant Real := Tan (Real (Nu1) / 2.0);
      D2     : constant Real := Tan (Real (Nu2) / 2.0);
      Half_Sqrt_P3_Over_Mu : constant Real :=
         0.5 * Sqrt (P_Val * P_Val * P_Val / Mu_Val);
      B1     : constant Real := D1 + (D1 * D1 * D1) / 3.0;
      B2     : constant Real := D2 + (D2 * D2 * D2) / 3.0;
   begin
      return Time_Seconds (Half_Sqrt_P3_Over_Mu * (B2 - B1));
   end Time_Of_Flight_Parabolic;

   function Time_Of_Flight (Nu1 : Angle_Radians;
                            Nu2 : Angle_Radians;
                            A   : Distance_Km;
                            E   : Real;
                            Mu  : Gravitational_Parameter) return Time_Seconds is
   begin
      if E < 1.0 - Parabolic_Threshold then
         return Time_Of_Flight_Elliptic (Nu1, Nu2, A, E, Mu);
      elsif E > 1.0 + Parabolic_Threshold then
         return Time_Of_Flight_Hyperbolic (Nu1, Nu2, A, E, Mu);
      else
         --  Parabolic regime: derive semi-latus rectum from (a, e).  For
         --  numerically-near-parabolic orbits with finite a this is well-
         --  defined and small; for the limiting true parabola (a -> +inf)
         --  the caller must instead invoke Time_Of_Flight_Parabolic with the
         --  semi-latus rectum directly.
         declare
            P : constant Distance_Km :=
               Distance_Km (abs (Real (A)) * abs (1.0 - E * E));
         begin
            if Real (P) <= 0.0 then
               raise Invalid_Orbit with
                  "Parabolic time of flight requires p > 0; "
                & "call Time_Of_Flight_Parabolic with explicit semi-latus rectum";
            end if;
            return Time_Of_Flight_Parabolic (Nu1, Nu2, P, Mu);
         end;
      end if;
   end Time_Of_Flight;

   ---------------------------------------------------------------------------
   -- Orbit Propagation
   ---------------------------------------------------------------------------

   procedure Propagate (R0    : Position_Vector;
                        V0    : Velocity_Vector;
                        Dt    : Time_Seconds;
                        Mu    : Gravitational_Parameter;
                        R_Out : out Position_Vector;
                        V_Out : out Velocity_Vector) is
      --  Universal variable propagation using f and g functions

      R0_Mag : constant Real := Magnitude (R0);
      V0_Mag_Sq : constant Real := Magnitude_Squared (V0);
      Mu_Val : constant Real := Real (Mu);
      Sqrt_Mu : constant Real := Sqrt (Mu_Val);
      Dt_Val : constant Real := Real (Dt);

      --  Radial velocity
      Vr0 : constant Real := Dot (R0, V0) / R0_Mag;

      --  Semi-major axis from energy
      Alpha : constant Real := 2.0 / R0_Mag - V0_Mag_Sq / Mu_Val;
      A : Real;

      --  Universal anomaly
      Chi : Real;
      Chi_Sq, Z : Real;
      C_Z, S_Z : Real;

      --  f and g functions
      F, G, F_Dot, G_Dot : Real;
      R_Mag : Real;

   begin
      if Dt_Val = 0.0 then
         R_Out := R0;
         V_Out := V0;
         return;
      end if;

      --  Handle different orbit types
      if abs (Alpha) < 1.0e-10 then
         --  Parabolic
         A := 1.0e12;  -- Large value
      else
         A := 1.0 / Alpha;
      end if;

      --  Solve for universal anomaly
      Chi := Solve_Kepler_Universal (Dt, Distance_Km (R0_Mag), Velocity_Km_S (Vr0),
                                     Distance_Km (A), Mu);

      Chi_Sq := Chi * Chi;
      Z := Alpha * Chi_Sq;
      C_Z := C (Z);
      S_Z := S (Z);

      --  Compute f and g functions
      F := 1.0 - (Chi_Sq / R0_Mag) * C_Z;
      G := Dt_Val - (Chi_Sq * Chi / Sqrt_Mu) * S_Z;

      --  New position
      R_Out := F * R0 + G * V0;
      R_Mag := Magnitude (R_Out);

      --  f_dot and g_dot
      F_Dot := (Sqrt_Mu / (R_Mag * R0_Mag)) * Chi * (Z * S_Z - 1.0);
      G_Dot := 1.0 - (Chi_Sq / R_Mag) * C_Z;

      --  New velocity
      V_Out := F_Dot * R0 + G_Dot * V0;
   end Propagate;

   procedure Propagate (State : in out State_Vector;
                        Dt    : Time_Seconds;
                        Mu    : Gravitational_Parameter) is
      R_New, V_New : Vector_3D;
   begin
      Propagate (State.Position, State.Velocity, Dt, Mu, R_New, V_New);
      State.Position := R_New;
      State.Velocity := V_New;
   end Propagate;

   function Propagate_Elements (Elements : Orbital_Elements;
                                Dt       : Time_Seconds;
                                Mu       : Gravitational_Parameter) return Orbital_Elements is
      Result : Orbital_Elements := Elements;
      N : Real;
      Delta_M : Real;
      M_New : Angle_Radians;
   begin
      --  Mean motion
      N := Mean_Motion (Elements.Semi_Major_Axis, Mu);

      --  Change in mean anomaly
      Delta_M := N * Real (Dt);

      --  Current mean anomaly
      M_New := True_To_Mean_Anomaly (Elements.True_Anomaly, Elements.Eccentricity);

      --  New mean anomaly
      M_New := Normalize_Angle (Angle_Radians (Real (M_New) + Delta_M));

      --  Convert back to true anomaly
      Result.True_Anomaly := Mean_To_True_Anomaly (M_New, Elements.Eccentricity);

      return Result;
   end Propagate_Elements;

end Hale_Orbital.Kepler;
