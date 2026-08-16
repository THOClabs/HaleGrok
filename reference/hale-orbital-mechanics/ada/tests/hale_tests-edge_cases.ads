-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Edge Case Tests (ISS-032)
-------------------------------------------------------------------------------
-- Comprehensive edge case tests for numerical robustness.
-- Tests boundary conditions, near-singular cases, and extreme values.
--
-- Extended for ISS-032: 20+ edge case tests covering:
--   - Vector singularities and precision boundaries
--   - Kepler solver convergence at extremes
--   - Orbital elements near-degenerate cases
--   - Lambert 180-degree transfers and multi-rev edge cases
--   - Propagation stability for high-e and near-parabolic orbits
--   - Stumpff function numerical stability
--   - Maneuver boundary conditions
--   - Three-body stability regions
--   - Matrix operations at singularities
-------------------------------------------------------------------------------

package Hale_Tests.Edge_Cases is

   --  Run all edge case tests
   procedure Run_All_Edge_Case_Tests;

   --  Vector edge cases (15+ tests)
   procedure Test_Vector_Edge_Cases;

   --  Kepler solver edge cases (10+ tests)
   procedure Test_Kepler_Edge_Cases;

   --  Orbital elements edge cases (12+ tests)
   procedure Test_Elements_Edge_Cases;

   --  Lambert solver edge cases (10+ tests)
   procedure Test_Lambert_Edge_Cases;

   --  Propagation edge cases (10+ tests)
   procedure Test_Propagation_Edge_Cases;

   --  NEW: Matrix edge cases (added for ISS-032)
   procedure Test_Matrix_Edge_Cases;

   --  NEW: Stumpff functions edge cases (added for ISS-032)
   procedure Test_Stumpff_Edge_Cases;

   --  NEW: Maneuvers edge cases (added for ISS-032)
   procedure Test_Maneuvers_Edge_Cases;

   --  NEW: Twobody edge cases (added for ISS-032)
   procedure Test_Twobody_Edge_Cases;

end Hale_Tests.Edge_Cases;
