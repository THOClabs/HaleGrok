-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Boundary Condition Tests (ISS-045)
-------------------------------------------------------------------------------
-- Tests for numerical behavior at orbital regime boundaries:
--   - Near-circular orbits (e → 0)
--   - Near-parabolic orbits (e → 1)
--   - Just-hyperbolic orbits (e > 1)
--   - Equatorial orbits (i → 0)
--   - Retrograde equatorial orbits (i → π)
--   - Anomaly boundary values (ν, M = 0, π, 2π)
--
-- DO-178C Reference: A-6.3.1 Test Completeness (Boundary Analysis)
-- RTM Mapping: HLR-1A-001 through HLR-1A-010 (boundary behavior)
-------------------------------------------------------------------------------

package Hale_Tests.Boundaries is

   --  Run all boundary condition tests
   procedure Run_All_Boundary_Tests;

   --  Eccentricity boundary tests
   procedure Test_Near_Circular_Eccentricity;      -- e → 0
   procedure Test_Near_Parabolic_Eccentricity;     -- e → 1-
   procedure Test_Just_Hyperbolic_Eccentricity;    -- e → 1+

   --  Inclination boundary tests
   procedure Test_Near_Equatorial_Prograde;        -- i → 0
   procedure Test_Near_Equatorial_Retrograde;      -- i → π

   --  Anomaly boundary tests
   procedure Test_True_Anomaly_Boundaries;         -- ν = 0, π, 2π
   procedure Test_Mean_Anomaly_Boundaries;         -- M = 0, π, 2π
   procedure Test_Eccentric_Anomaly_Boundaries;    -- E = 0, π, 2π

   --  Special orbit boundary tests
   procedure Test_LEO_Altitude_Boundary;           -- h = 200 km
   procedure Test_GEO_Radius_Boundary;             -- r = 42164 km

end Hale_Tests.Boundaries;
