-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Floating-Point Determinism Tests (ISS-024)
-------------------------------------------------------------------------------
-- Tests to validate floating-point determinism within a single platform
-- and provide reference values for cross-platform validation.
--
-- Purpose:
--   1. Verify repeated calculations produce identical results
--   2. Generate reference values for cross-platform testing
--   3. Document expected precision tolerances
-------------------------------------------------------------------------------

package Hale_Tests.Determinism is

   --  Run all determinism tests
   procedure Run_All_Determinism_Tests;

   --  Test that repeated calculations produce identical results
   procedure Test_Calculation_Repeatability;

   --  Test accumulation stability (Kahan summation properties)
   procedure Test_Summation_Stability;

   --  Generate and display reference values for cross-platform validation
   procedure Generate_Reference_Values;

   --  Test against reference values (tolerance-based)
   procedure Test_Against_References;

end Hale_Tests.Determinism;
