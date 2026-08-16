-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Test Runner Implementation
-------------------------------------------------------------------------------

with Ada.Text_IO;

package body Hale_Tests.Runner is

   package IO renames Ada.Text_IO;
   use Real_Functions;

   --  Internal counters
   G_Total_Tests  : Natural := 0;
   G_Tests_Passed : Natural := 0;
   G_Tests_Failed : Natural := 0;

   ---------------------------------------------------------------------------
   -- Assertion Implementations
   ---------------------------------------------------------------------------

   procedure Assert (Condition : Boolean;
                     Message   : String := "Assertion failed") is
   begin
      if not Condition then
         raise Constraint_Error with Message;
      end if;
   end Assert;

   procedure Assert_Equal (Expected : Real;
                           Actual   : Real;
                           Tolerance : Real := 1.0e-10;
                           Message   : String := "Values not equal") is
   begin
      if abs (Expected - Actual) > Tolerance then
         raise Constraint_Error with Message &
            " (expected " & Real'Image (Expected) &
            ", got " & Real'Image (Actual) & ")";
      end if;
   end Assert_Equal;

   procedure Assert_Equal (Expected : Integer;
                           Actual   : Integer;
                           Message  : String := "Integers not equal") is
   begin
      if Expected /= Actual then
         raise Constraint_Error with Message &
            " (expected " & Integer'Image (Expected) &
            ", got " & Integer'Image (Actual) & ")";
      end if;
   end Assert_Equal;

   procedure Assert_Equal (Expected : Vector_3D;
                           Actual   : Vector_3D;
                           Tolerance : Real := 1.0e-10;
                           Message   : String := "Vectors not equal") is
   begin
      if abs (Expected (1) - Actual (1)) > Tolerance or
         abs (Expected (2) - Actual (2)) > Tolerance or
         abs (Expected (3) - Actual (3)) > Tolerance
      then
         raise Constraint_Error with Message;
      end if;
   end Assert_Equal;

   procedure Assert_Near (Expected : Real;
                          Actual   : Real;
                          Relative_Tolerance : Real := 1.0e-6;
                          Message  : String := "Values not near") is
      Tol : Real;
   begin
      if abs (Expected) > 1.0e-15 then
         Tol := abs (Expected) * Relative_Tolerance;
      else
         Tol := Relative_Tolerance;
      end if;

      if abs (Expected - Actual) > Tol then
         raise Constraint_Error with Message &
            " (expected " & Real'Image (Expected) &
            ", got " & Real'Image (Actual) & ")";
      end if;
   end Assert_Near;

   procedure Assert_Positive (Value   : Real;
                              Message : String := "Value not positive") is
   begin
      if Value <= 0.0 then
         raise Constraint_Error with Message &
            " (got " & Real'Image (Value) & ")";
      end if;
   end Assert_Positive;

   procedure Assert_Negative (Value   : Real;
                              Message : String := "Value not negative") is
   begin
      if Value >= 0.0 then
         raise Constraint_Error with Message &
            " (got " & Real'Image (Value) & ")";
      end if;
   end Assert_Negative;

   procedure Assert_In_Range (Value : Real;
                              Low   : Real;
                              High  : Real;
                              Message : String := "Value out of range") is
   begin
      if Value < Low or Value > High then
         raise Constraint_Error with Message &
            " (expected " & Real'Image (Low) & " to " & Real'Image (High) &
            ", got " & Real'Image (Value) & ")";
      end if;
   end Assert_In_Range;

   ---------------------------------------------------------------------------
   -- Test Execution
   ---------------------------------------------------------------------------

   procedure Run_Test (Name   : String;
                       Passed : Boolean) is
   begin
      G_Total_Tests := G_Total_Tests + 1;
      if Passed then
         G_Tests_Passed := G_Tests_Passed + 1;
         IO.Put_Line ("  [PASS] " & Name);
      else
         G_Tests_Failed := G_Tests_Failed + 1;
         IO.Put_Line ("  [FAIL] " & Name);
      end if;
   end Run_Test;

   procedure Record_Results (Passed : Natural;
                             Failed : Natural) is
   begin
      G_Total_Tests := G_Total_Tests + Passed + Failed;
      G_Tests_Passed := G_Tests_Passed + Passed;
      G_Tests_Failed := G_Tests_Failed + Failed;
   end Record_Results;

   procedure Start_Suite (Name : String) is
   begin
      IO.Put_Line ("Testing " & Name & "...");
   end Start_Suite;

   procedure End_Suite is
   begin
      IO.New_Line;
   end End_Suite;

   function Total_Tests return Natural is (G_Total_Tests);
   function Tests_Passed return Natural is (G_Tests_Passed);
   function Tests_Failed return Natural is (G_Tests_Failed);

   procedure Print_Summary is
   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Test Summary");
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Total:  " & Natural'Image (G_Total_Tests));
      IO.Put_Line ("  Passed: " & Natural'Image (G_Tests_Passed));
      IO.Put_Line ("  Failed: " & Natural'Image (G_Tests_Failed));
      IO.Put_Line ("=========================================");

      if G_Tests_Failed = 0 then
         IO.Put_Line ("  All tests passed!");
      else
         IO.Put_Line ("  Some tests failed.");
      end if;
   end Print_Summary;

   procedure Reset is
   begin
      G_Total_Tests := 0;
      G_Tests_Passed := 0;
      G_Tests_Failed := 0;
   end Reset;

end Hale_Tests.Runner;
