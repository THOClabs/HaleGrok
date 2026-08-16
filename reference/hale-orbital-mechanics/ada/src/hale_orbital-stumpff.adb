-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Stumpff Functions Body
-------------------------------------------------------------------------------

with Ada.Numerics.Generic_Elementary_Functions;

package body Hale_Orbital.Stumpff
   with SPARK_Mode => Off  --  Body uses generic instantiation
is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   --  Threshold for using Taylor series (numerical stability).
   --  The closed forms (1-cos(sqrt z))/z and (sqrt z - sin(sqrt z))/z^1.5
   --  cancel catastrophically for small |z| (at z ~ 1e-8 the relative error
   --  is ~1e-8, which injected microsecond-level TOF noise into Lambert
   --  around parabolic boundaries).  The 5-term series below is accurate to
   --  ~1e-19 at |z| = 1e-2; the residual closed-form cancellation just
   --  outside the seam measures ~4e-14 rel for C and ~4e-13 rel for S
   --  (adversarially scanned) — five orders better than the old seam.
   --  Was 1.0e-10 — far too small.  See DEC-009.
   Taylor_Threshold : constant Real := 1.0e-2;

   ---------------------------------------------------------------------------
   -- Stumpff C Function
   ---------------------------------------------------------------------------

   function C (Z : Real) return Real is
      Sqrt_Z : Real;
      Result : Real;
   begin
      if abs (Z) < Taylor_Threshold then
         --  Taylor series: C(z) = 1/2 - z/24 + z²/720 - z³/40320 + ...
         --  Use sufficient terms for machine precision
         Result := 0.5 - Z / 24.0 + (Z * Z) / 720.0 -
                   (Z * Z * Z) / 40320.0 + (Z * Z * Z * Z) / 3628800.0;
      elsif Z > 0.0 then
         --  Elliptic case: C(z) = (1 - cos(sqrt(z))) / z
         Sqrt_Z := Sqrt (Z);
         Result := (1.0 - Cos (Sqrt_Z)) / Z;
      else
         --  Hyperbolic case: C(z) = (cosh(sqrt(-z)) - 1) / (-z)
         Sqrt_Z := Sqrt (-Z);
         --  cosh(x) = (e^x + e^(-x)) / 2
         Result := ((Exp (Sqrt_Z) + Exp (-Sqrt_Z)) / 2.0 - 1.0) / (-Z);
      end if;

      --  Ensure non-negative (numerical safety)
      if Result < 0.0 then
         Result := 0.0;
      end if;

      return Result;
   end C;

   ---------------------------------------------------------------------------
   -- Stumpff S Function
   ---------------------------------------------------------------------------

   function S (Z : Real) return Real is
      Sqrt_Z : Real;
      Sqrt_Z_Cubed : Real;
      Result : Real;
   begin
      if abs (Z) < Taylor_Threshold then
         --  Taylor series: S(z) = 1/6 - z/120 + z²/5040 - z³/362880 + ...
         Result := 1.0 / 6.0 - Z / 120.0 + (Z * Z) / 5040.0 -
                   (Z * Z * Z) / 362880.0 + (Z * Z * Z * Z) / 39916800.0;
      elsif Z > 0.0 then
         --  Elliptic case: S(z) = (sqrt(z) - sin(sqrt(z))) / sqrt(z)³
         Sqrt_Z := Sqrt (Z);
         Sqrt_Z_Cubed := Sqrt_Z * Sqrt_Z * Sqrt_Z;
         Result := (Sqrt_Z - Sin (Sqrt_Z)) / Sqrt_Z_Cubed;
      else
         --  Hyperbolic case: S(z) = (sinh(sqrt(-z)) - sqrt(-z)) / sqrt(-z)³
         Sqrt_Z := Sqrt (-Z);
         Sqrt_Z_Cubed := Sqrt_Z * Sqrt_Z * Sqrt_Z;
         --  sinh(x) = (e^x - e^(-x)) / 2
         Result := ((Exp (Sqrt_Z) - Exp (-Sqrt_Z)) / 2.0 - Sqrt_Z) / Sqrt_Z_Cubed;
      end if;

      --  Ensure non-negative (numerical safety)
      if Result < 0.0 then
         Result := 0.0;
      end if;

      return Result;
   end S;

   ---------------------------------------------------------------------------
   -- Derivative Functions
   ---------------------------------------------------------------------------

   function C_Derivative (Z : Real) return Real is
      C_Z : constant Real := C (Z);
      S_Z : constant Real := S (Z);
   begin
      --  dC/dz = (1 - 2*C(z) - z*S(z)) / (2*z)
      return (1.0 - 2.0 * C_Z - Z * S_Z) / (2.0 * Z);
   end C_Derivative;

   function S_Derivative (Z : Real) return Real is
      C_Z : constant Real := C (Z);
      S_Z : constant Real := S (Z);
   begin
      --  dS/dz = (C(z) - 3*S(z)) / (2*z)
      return (C_Z - 3.0 * S_Z) / (2.0 * Z);
   end S_Derivative;

end Hale_Orbital.Stumpff;
