-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Vallado Validation Tests
-------------------------------------------------------------------------------
-- Validation test cases from Vallado's "Fundamentals of Astrodynamics
-- and Applications" for independent verification.
--
-- Reference: Vallado, D.A. (2013). Fundamentals of Astrodynamics and
-- Applications, 4th Edition. Microcosm Press.
-------------------------------------------------------------------------------

package Hale_Tests.Vallado is

   --  Run all Vallado validation tests
   procedure Run_All_Vallado_Tests;

   --  Vallado Example 2-1: RV to COE
   procedure Test_Vallado_RV_To_COE;

   --  Vallado Example 2-2: COE to RV
   procedure Test_Vallado_COE_To_RV;

   --  Vallado Example 2-3: Kepler's Equation
   procedure Test_Vallado_Kepler;

   --  Vallado Example 5-1: Hohmann Transfer
   procedure Test_Vallado_Hohmann;

   --  Vallado Example 5-5: Plane Change
   procedure Test_Vallado_Plane_Change;

   --  Vallado Example 7-1: Lambert Problem
   procedure Test_Vallado_Lambert;

end Hale_Tests.Vallado;
