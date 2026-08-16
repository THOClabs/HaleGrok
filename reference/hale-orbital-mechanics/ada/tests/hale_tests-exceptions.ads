-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Exception Path Tests (ISS-012)
-------------------------------------------------------------------------------
-- Tests for exception handling and error recovery paths.
-- Verifies that the library properly raises expected exceptions:
--   - Convergence_Error: Iterative solver non-convergence
--   - Invalid_Orbit: Invalid orbital parameters
--   - Physical_Error: Physics constraint violations
--   - Singularity_Error: Singular geometric configurations
--
-- DO-178C Reference: A-6.3.1 Test Completeness (Exception Paths)
-- RTM Mapping: NFR-ERR-001 through NFR-ERR-005
-------------------------------------------------------------------------------

package Hale_Tests.Exceptions is

   --  Run all exception path tests
   procedure Run_All_Exception_Tests;

   --  Test Convergence_Error exceptions
   --  Tests: Force non-convergence in Kepler and Lambert solvers
   --  RTM: NFR-ERR-001
   procedure Test_Convergence_Error_Paths;

   --  Test Invalid_Orbit exceptions
   --  Tests: Invalid orbital elements that violate physical constraints
   --  RTM: NFR-ERR-002
   procedure Test_Invalid_Orbit_Paths;

   --  Test Physical_Error exceptions
   --  Tests: Operations that violate conservation laws
   --  RTM: NFR-ERR-003
   procedure Test_Physical_Error_Paths;

   --  Test Singularity_Error exceptions
   --  Tests: Singular geometric configurations (180-deg transfers, etc.)
   --  RTM: NFR-ERR-004
   procedure Test_Singularity_Error_Paths;

   --  Test Constraint_Error paths
   --  Tests: Array bounds, numeric overflow scenarios
   --  RTM: NFR-ERR-005
   procedure Test_Constraint_Error_Paths;

   --  Test exception message quality
   --  Verifies exceptions contain meaningful diagnostic information
   --  RTM: NFR-ERR-006
   procedure Test_Exception_Messages;

end Hale_Tests.Exceptions;
