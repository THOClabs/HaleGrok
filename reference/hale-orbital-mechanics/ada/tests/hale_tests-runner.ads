-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Test Runner
-------------------------------------------------------------------------------
-- Executes all test suites and reports results.
-- Provides assertion helpers compatible with AUnit patterns.
-------------------------------------------------------------------------------

with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Types; use Hale_Orbital.Types;
with Hale_Orbital.Vectors; use Hale_Orbital.Vectors;

package Hale_Tests.Runner is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);

   --  Assertion procedures (AUnit-compatible signatures)
   procedure Assert (Condition : Boolean;
                     Message   : String := "Assertion failed");

   procedure Assert_Equal (Expected : Real;
                           Actual   : Real;
                           Tolerance : Real := 1.0e-10;
                           Message   : String := "Values not equal");

   procedure Assert_Equal (Expected : Integer;
                           Actual   : Integer;
                           Message  : String := "Integers not equal");

   procedure Assert_Equal (Expected : Vector_3D;
                           Actual   : Vector_3D;
                           Tolerance : Real := 1.0e-10;
                           Message   : String := "Vectors not equal");

   procedure Assert_Near (Expected : Real;
                          Actual   : Real;
                          Relative_Tolerance : Real := 1.0e-6;
                          Message  : String := "Values not near");

   procedure Assert_Positive (Value   : Real;
                              Message : String := "Value not positive");

   procedure Assert_Negative (Value   : Real;
                              Message : String := "Value not negative");

   procedure Assert_In_Range (Value : Real;
                              Low   : Real;
                              High  : Real;
                              Message : String := "Value out of range");

   --  Test execution interface
   procedure Run_Test (Name   : String;
                       Passed : Boolean);

   --  Fold externally-tallied suite results into the shared counters so
   --  their failures reach the process exit status (used by suites that
   --  keep local counters and do their own printing).
   procedure Record_Results (Passed : Natural;
                             Failed : Natural);

   procedure Start_Suite (Name : String);
   procedure End_Suite;

   --  Get current counts
   function Total_Tests return Natural;
   function Tests_Passed return Natural;
   function Tests_Failed return Natural;

   --  Print final summary
   procedure Print_Summary;

   --  Reset counters
   procedure Reset;

end Hale_Tests.Runner;
