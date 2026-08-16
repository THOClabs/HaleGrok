-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Lambert Multi-Revolution Tests (ISS-030)
-------------------------------------------------------------------------------
-- Comprehensive test suite for multi-revolution Lambert solver validation.
--
-- Test Coverage:
--   - Single revolution with low/high energy branches
--   - Multi-revolution (1, 2, 3 revs) transfers
--   - Minimum TOF calculations per revolution
--   - Solution counting and bracketing
--   - Edge cases near revolution boundaries
--
-- Reference: Vallado (2013) Chapter 7, Izzo (2015) Lambert Algorithm
-------------------------------------------------------------------------------

package Hale_Tests.Lambert_MultiRev is

   --  Run all multi-revolution Lambert tests
   procedure Run_All_Lambert_MultiRev_Tests;

   --  Single-revolution variants
   procedure Test_Single_Rev_Short_Way;
   procedure Test_Single_Rev_Long_Way;

   --  Multi-revolution fundamentals
   procedure Test_Multi_Rev_Min_TOF;
   procedure Test_Multi_Rev_Solution_Counting;

   --  N-revolution transfers
   procedure Test_One_Revolution_Transfer;
   procedure Test_Two_Revolution_Transfer;
   procedure Test_Three_Revolution_Transfer;

   --  Edge cases and boundaries
   procedure Test_Revolution_Boundary_Cases;
   procedure Test_Energy_Branch_Selection;

   --  Validation against published results
   procedure Test_Published_Multi_Rev_Cases;

end Hale_Tests.Lambert_MultiRev;
