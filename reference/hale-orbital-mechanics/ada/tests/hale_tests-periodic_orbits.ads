-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Periodic Orbit Test Suite (ISS-034)
-------------------------------------------------------------------------------
-- Tests for periodic orbit computation in the CR3BP:
--   - State Transition Matrix (STM) computation
--   - Monodromy matrix and Floquet analysis
--   - Lyapunov orbit finding (planar periodic orbits)
--   - Halo orbit finding (3D periodic orbits)
--   - Richardson third-order approximation
--   - Orbit family generation
--
-- Reference: Richardson (1980), Howell (1984), Koon et al. (2000)
-------------------------------------------------------------------------------

package Hale_Tests.Periodic_Orbits is

   --  Run all periodic orbit tests
   procedure Run_All_Periodic_Orbit_Tests;

   --  Test State Transition Matrix computation
   procedure Test_STM_Identity_Initial;
   procedure Test_STM_Propagation;
   procedure Test_STM_Symplectic_Property;

   --  Test Monodromy matrix computation
   procedure Test_Monodromy_Matrix;
   procedure Test_Monodromy_Determinant;

   --  Test Floquet analysis
   procedure Test_Floquet_Multipliers;
   procedure Test_Floquet_Reciprocal_Pairs;

   --  Test Lyapunov orbit finding
   procedure Test_Lyapunov_L1_Earth_Moon;
   procedure Test_Lyapunov_L2_Earth_Moon;
   procedure Test_Lyapunov_Periodicity;

   --  Test Richardson approximation for Halo orbits
   procedure Test_Richardson_Guess_L1;
   procedure Test_Richardson_Guess_L2;

   --  Test Halo orbit finding
   procedure Test_Halo_L1_Northern;
   procedure Test_Halo_L2_Southern;
   procedure Test_Halo_Periodicity;

   --  Test orbit family generation
   procedure Test_Lyapunov_Family;

   --  Test Jacobi constant conservation
   procedure Test_Periodic_Orbit_Jacobi_Conservation;

end Hale_Tests.Periodic_Orbits;
