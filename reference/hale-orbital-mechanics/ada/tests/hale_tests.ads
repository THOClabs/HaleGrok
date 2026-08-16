-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Test Framework (AUnit-compatible structure)
-------------------------------------------------------------------------------
-- Provides a lightweight test framework structure compatible with AUnit.
-- Can be migrated to full AUnit when infrastructure is available.
--
-- Structure follows AUnit patterns:
--   - Test_Case: Individual test procedure
--   - Test_Suite: Collection of related tests
--   - Test_Runner: Executes all suites and reports results
-------------------------------------------------------------------------------

package Hale_Tests is

   pragma Pure;

   --  Test result status
   type Test_Status is (Passed, Failed, Error, Skipped);

   --  Maximum lengths for test names and messages
   Max_Name_Length : constant := 100;
   Max_Message_Length : constant := 200;

   --  Test result record
   type Test_Result is record
      Name    : String (1 .. Max_Name_Length);
      Name_Length : Natural;
      Status  : Test_Status;
      Message : String (1 .. Max_Message_Length);
      Message_Length : Natural;
   end record;

   --  Suite result summary
   type Suite_Summary is record
      Total   : Natural;
      Passed  : Natural;
      Failed  : Natural;
      Errors  : Natural;
      Skipped : Natural;
   end record;

   --  Initialize a suite summary
   function Empty_Summary return Suite_Summary is
      ((Total => 0, Passed => 0, Failed => 0, Errors => 0, Skipped => 0));

   --  Combine summaries
   function "+" (Left, Right : Suite_Summary) return Suite_Summary is
      ((Total   => Left.Total + Right.Total,
        Passed  => Left.Passed + Right.Passed,
        Failed  => Left.Failed + Right.Failed,
        Errors  => Left.Errors + Right.Errors,
        Skipped => Left.Skipped + Right.Skipped));

end Hale_Tests;
