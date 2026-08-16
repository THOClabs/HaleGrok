-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Parallel Propagation Test Suite (ISS-031)
-------------------------------------------------------------------------------
-- Tests for Ada 2022 parallel propagation features including:
--   - Correctness: Parallel results match sequential results
--   - Determinism: Repeated parallel runs produce identical results
--   - Ensemble: Monte Carlo uncertainty propagation
--   - Statistics: Compute_Statistics validation
--
-- Reference: HYBRID_PATH_MASTER_PLAN (Parallel Safety)
-------------------------------------------------------------------------------

package Hale_Tests.Parallel is

   --  Run all parallel propagation tests
   procedure Run_All_Parallel_Tests;

   --  Parallel results match sequential (RK78)
   procedure Test_Parallel_Matches_Sequential_RK78;

   --  Parallel results match sequential (RK4)
   procedure Test_Parallel_Matches_Sequential_RK4;

   --  Repeated parallel runs are deterministic
   procedure Test_Parallel_Determinism;

   --  Monte Carlo ensemble propagation
   procedure Test_Monte_Carlo_Ensemble;

   --  Statistics computation validation
   procedure Test_Statistics_Computation;

   --  Single-element array edge case
   procedure Test_Single_Element_Array;

   --  Large ensemble (100+ samples)
   procedure Test_Large_Ensemble;

   --  Energy conservation in parallel propagation
   procedure Test_Parallel_Energy_Conservation;

   --  Mixed orbit types in ensemble
   procedure Test_Mixed_Orbit_Ensemble;

   --  Zero-length propagation (T_Start = T_End)
   procedure Test_Zero_Duration_Parallel;

end Hale_Tests.Parallel;
