-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Negative Tests (ISS-011)
-------------------------------------------------------------------------------
-- Tests for invalid inputs and error handling.
-- Verifies that the library properly rejects:
--   - Invalid eccentricity values (e >= 1 for elliptic, e <= 1 for hyperbolic)
--   - Negative or zero values where positive required (SMA, radius, Mu)
--   - NaN and Inf inputs
--   - Zero vectors where non-zero required
--   - Invalid TOF for Lambert problem
--
-- DO-178C Reference: A-6.3.1 Test Completeness
-- RTM Mapping: NFR-ROB-001 through NFR-ROB-004
-------------------------------------------------------------------------------

package Hale_Tests.Negative is

   --  Run all negative tests
   procedure Run_All_Negative_Tests;

   --  Invalid eccentricity tests
   --  Tests: e = 1.0, e = 1.001, e = -0.1 for elliptic functions
   --  RTM: NFR-ROB-001
   procedure Test_Invalid_Eccentricity;

   --  Invalid SMA tests
   --  Tests: a = 0, a < 0 for functions requiring positive SMA
   --  RTM: NFR-ROB-001
   procedure Test_Invalid_SMA;

   --  Invalid radius tests
   --  Tests: r = 0, r < 0 for functions requiring positive radius
   --  RTM: NFR-ROB-001
   procedure Test_Invalid_Radius;

   --  Invalid gravitational parameter tests
   --  Tests: Mu = 0, Mu < 0
   --  RTM: NFR-ROB-001
   procedure Test_Invalid_Mu;

   --  Zero vector tests
   --  Tests: Zero position/velocity vectors where non-zero required
   --  RTM: NFR-ROB-002
   procedure Test_Zero_Vectors;

   --  Invalid TOF tests for Lambert
   --  Tests: TOF <= 0, TOF below minimum energy
   --  RTM: NFR-ROB-003
   procedure Test_Invalid_TOF;

   --  Invalid tolerance tests
   --  Tests: Tolerance <= 0, Tolerance too tight
   --  RTM: NFR-ROB-004
   procedure Test_Invalid_Tolerance;

   --  Invalid angular momentum tests
   --  Tests: H = 0 for radial velocity functions
   --  RTM: NFR-ROB-001
   procedure Test_Invalid_Angular_Momentum;

end Hale_Tests.Negative;
