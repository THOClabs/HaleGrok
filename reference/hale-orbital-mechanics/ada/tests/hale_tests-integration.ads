-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Integration Test Suite (ISS-037)
-------------------------------------------------------------------------------
-- End-to-end integration tests validating that multiple packages work
-- together correctly for real mission scenarios.
--
-- Test Scenarios:
--   - Lambert + Propagation: Verify Lambert solution propagates correctly
--   - Elements + State: Round-trip conversions maintain accuracy
--   - Maneuvers + Propagation: Verify maneuver DV produces expected orbit
--   - Full Mission Profile: LEO to GEO transfer simulation
--   - Three-Body + Propagation: CR3BP dynamics integration
--
-- Reference: HYBRID_PATH_MASTER_PLAN (Integration Gates)
-------------------------------------------------------------------------------

package Hale_Tests.Integration is

   --  Run all integration tests
   procedure Run_All_Integration_Tests;

   --  Lambert + Propagation: Solve Lambert, then propagate to verify TOF
   procedure Test_Lambert_Propagation_Consistency;

   --  Elements conversion round-trip across packages
   procedure Test_Elements_State_Round_Trip;

   --  Hohmann transfer with propagation verification
   procedure Test_Hohmann_Transfer_Propagation;

   --  Full LEO to GEO mission profile
   procedure Test_LEO_GEO_Mission_Profile;

   --  Three-body and propagation integration
   procedure Test_Threebody_Propagation_Integration;

   --  Interplanetary trajectory integration
   procedure Test_Interplanetary_Integration;

   --  Energy and angular momentum conservation across operations
   procedure Test_Conservation_Laws_Integration;

end Hale_Tests.Integration;
