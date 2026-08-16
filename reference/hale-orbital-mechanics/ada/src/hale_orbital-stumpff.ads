-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Stumpff Functions
-------------------------------------------------------------------------------
-- Stumpff functions C(z) and S(z) for universal variable formulation.
-- These functions are fundamental to solving Kepler's equation for all
-- orbit types (elliptic, parabolic, hyperbolic).
--
-- Reference: Battin, R.H. (1999). An Introduction to the Mathematics and
--            Methods of Astrodynamics. AIAA Education Series. Section 4.4.
--
-- SPARK Status: contracts defined on the spec; body is SPARK_Mode Off
-- (generic instantiation) and has NOT been proven — gnatprove has never run.
-------------------------------------------------------------------------------

with Hale_Orbital.Types; use Hale_Orbital.Types;

package Hale_Orbital.Stumpff
   with SPARK_Mode => On,
        Pure
is

   ---------------------------------------------------------------------------
   -- Stumpff Function C(z)
   ---------------------------------------------------------------------------
   --  C(z) = (1 - cos(sqrt(z))) / z          for z > 0 (elliptic)
   --  C(z) = (cosh(sqrt(-z)) - 1) / (-z)     for z < 0 (hyperbolic)
   --  C(0) = 1/2                              (parabolic limit)
   --
   --  Taylor series near z=0: C(z) = 1/2 - z/24 + z²/720 - z³/40320 + ...
   --
   --  Properties:
   --    C(z) > 0 for all real z
   --    C(0) = 0.5
   --    C(z) → 0 as z → +∞
   --    C(z) → +∞ as z → -∞

   function C (Z : Real) return Real
      with Post => C'Result >= 0.0,
           Global => null;
   --  Stumpff C function with guaranteed non-negative result

   ---------------------------------------------------------------------------
   -- Stumpff Function S(z)
   ---------------------------------------------------------------------------
   --  S(z) = (sqrt(z) - sin(sqrt(z))) / sqrt(z)³    for z > 0 (elliptic)
   --  S(z) = (sinh(sqrt(-z)) - sqrt(-z)) / sqrt(-z)³ for z < 0 (hyperbolic)
   --  S(0) = 1/6                                      (parabolic limit)
   --
   --  Taylor series near z=0: S(z) = 1/6 - z/120 + z²/5040 - z³/362880 + ...
   --
   --  Properties:
   --    S(z) > 0 for all real z
   --    S(0) = 1/6 ≈ 0.166667
   --    S(z) → 0 as z → +∞
   --    S(z) → +∞ as z → -∞

   function S (Z : Real) return Real
      with Post => S'Result >= 0.0,
           Global => null;
   --  Stumpff S function with guaranteed non-negative result

   ---------------------------------------------------------------------------
   -- Derivative Relations (useful for iteration)
   ---------------------------------------------------------------------------
   --  dC/dz = (1 - 2*C(z) - z*S(z)) / (2*z)  for z ≠ 0
   --  dS/dz = (C(z) - 3*S(z)) / (2*z)        for z ≠ 0

   function C_Derivative (Z : Real) return Real
      with Pre => abs (Z) > 1.0e-10,
           Global => null;
   --  Derivative of C(z) with respect to z

   function S_Derivative (Z : Real) return Real
      with Pre => abs (Z) > 1.0e-10,
           Global => null;
   --  Derivative of S(z) with respect to z

   ---------------------------------------------------------------------------
   -- Validation Constants
   ---------------------------------------------------------------------------
   --  Reference values for testing (from Battin, Vallado)

   --  C(0) = 0.5
   C_At_Zero : constant Real := 0.5;

   --  S(0) = 1/6
   S_At_Zero : constant Real := 1.0 / 6.0;

   --  C(1) ≈ 0.459697694
   C_At_One : constant Real := 0.459697694;

   --  S(1) ≈ 0.158529167
   S_At_One : constant Real := 0.158529167;

   --  C(-1) ≈ 0.543080635
   C_At_Neg_One : constant Real := 0.543080635;

   --  S(-1) ≈ 0.175201194
   S_At_Neg_One : constant Real := 0.175201194;

   --  C(10) ≈ 0.183772169
   C_At_Ten : constant Real := 0.183772169;

   --  S(10) ≈ 0.047514285
   S_At_Ten : constant Real := 0.047514285;

end Hale_Orbital.Stumpff;
