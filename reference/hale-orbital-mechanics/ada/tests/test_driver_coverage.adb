-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Coverage Test Driver
-------------------------------------------------------------------------------
-- Test driver designed for GNATcoverage decision coverage analysis.
-- DO-178C Level B compliance: Statement + Decision Coverage
--
-- Reference: docs/certification/level-b-roadmap.md Phase 1.2
-- RTM: NFR-COV-001 (Coverage Infrastructure)
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Calendar;
with Ada.Directories;
with Ada.Exceptions;

--  Import all test packages
with Hale_Tests;
with Hale_Tests.Vallado;
with Hale_Tests.Edge_Cases;
with Hale_Tests.Negative;
with Hale_Tests.Exceptions;
with Hale_Tests.Boundaries;
with Hale_Tests.Periodic_Orbits;

procedure Test_Driver_Coverage is

   package IO renames Ada.Text_IO;
   package CL renames Ada.Command_Line;
   package Cal renames Ada.Calendar;
   package Dir renames Ada.Directories;

   --  Test suite selection
   type Test_Suite is (All_Suites, Vallado, Edge_Cases, Negative,
                       Exception_Paths, Boundaries, Periodic_Orbits);

   --  Coverage results tracking
   type Coverage_Results is record
      Total_Tests   : Natural := 0;
      Passed_Tests  : Natural := 0;
      Failed_Tests  : Natural := 0;
      Skipped_Tests : Natural := 0;
      Start_Time    : Cal.Time;
      End_Time      : Cal.Time;
   end record;

   Results : Coverage_Results;
   Selected_Suite : Test_Suite := All_Suites;
   Verbose : Boolean := False;
   Generate_XML : Boolean := False;

   ---------------------------------------------------------------------------
   --  Parse command line arguments
   ---------------------------------------------------------------------------
   procedure Parse_Arguments is
   begin
      for I in 1 .. CL.Argument_Count loop
         declare
            Arg : constant String := CL.Argument (I);
         begin
            if Arg = "--verbose" or Arg = "-v" then
               Verbose := True;
            elsif Arg = "--xml" then
               Generate_XML := True;
            elsif Arg = "--suite=vallado" then
               Selected_Suite := Vallado;
            elsif Arg = "--suite=edge" then
               Selected_Suite := Edge_Cases;
            elsif Arg = "--suite=negative" then
               Selected_Suite := Negative;
            elsif Arg = "--suite=exceptions" then
               Selected_Suite := Exception_Paths;
            elsif Arg = "--suite=boundaries" then
               Selected_Suite := Boundaries;
            elsif Arg = "--suite=periodic" then
               Selected_Suite := Periodic_Orbits;
            elsif Arg = "--suite=all" then
               Selected_Suite := All_Suites;
            elsif Arg = "--help" or Arg = "-h" then
               IO.Put_Line ("Usage: test_driver_coverage [OPTIONS]");
               IO.Put_Line ("");
               IO.Put_Line ("Options:");
               IO.Put_Line ("  --suite=<name>  Run specific test suite");
               IO.Put_Line ("                  (vallado, edge, negative, exceptions,");
               IO.Put_Line ("                   boundaries, periodic, all)");
               IO.Put_Line ("  --verbose, -v   Enable verbose output");
               IO.Put_Line ("  --xml           Generate JUnit XML output");
               IO.Put_Line ("  --help, -h      Show this help message");
               IO.Put_Line ("");
               IO.Put_Line ("Coverage Workflow:");
               IO.Put_Line ("  1. gnatcov instrument -P coverage.gpr");
               IO.Put_Line ("  2. gprbuild -P coverage.gpr");
               IO.Put_Line ("  3. gnatcov run -P coverage.gpr bin/test_driver_coverage");
               IO.Put_Line ("  4. gnatcov coverage -P coverage.gpr --level=stmt+decision");
               return;
            end if;
         end;
      end loop;
   end Parse_Arguments;

   ---------------------------------------------------------------------------
   --  Print banner with coverage mode indicator
   ---------------------------------------------------------------------------
   procedure Print_Banner is
   begin
      IO.Put_Line ("==========================================================");
      IO.Put_Line ("  HALE Orbital Mechanics - Coverage Test Driver");
      IO.Put_Line ("  DO-178C Level B: Statement + Decision Coverage");
      IO.Put_Line ("==========================================================");
      IO.Put_Line ("  Suite: " & Test_Suite'Image (Selected_Suite));
      IO.Put_Line ("  Verbose: " & Boolean'Image (Verbose));
      IO.New_Line;
   end Print_Banner;

   ---------------------------------------------------------------------------
   --  Run a test suite with coverage tracking
   ---------------------------------------------------------------------------
   procedure Run_Suite (Name : String; Suite_Proc : access procedure) is
   begin
      if Verbose then
         IO.Put_Line ("--- Running: " & Name & " ---");
      end if;

      begin
         Suite_Proc.all;
         if Verbose then
            IO.Put_Line ("  [COMPLETE] " & Name);
         end if;
      exception
         when E : others =>
            IO.Put_Line ("  [ERROR] " & Name & ": " &
                         Ada.Exceptions.Exception_Message (E));
            Results.Failed_Tests := Results.Failed_Tests + 1;
      end;
   end Run_Suite;

   ---------------------------------------------------------------------------
   --  Run selected test suites
   ---------------------------------------------------------------------------
   procedure Run_Tests is
   begin
      case Selected_Suite is
         when All_Suites =>
            Run_Suite ("Vallado Reference Tests",
                       Hale_Tests.Vallado.Run_All_Vallado_Tests'Access);
            Run_Suite ("Edge Case Tests",
                       Hale_Tests.Edge_Cases.Run_All_Edge_Case_Tests'Access);
            Run_Suite ("Negative Input Tests",
                       Hale_Tests.Negative.Run_All_Negative_Tests'Access);
            Run_Suite ("Exception Path Tests",
                       Hale_Tests.Exceptions.Run_All_Exception_Tests'Access);
            Run_Suite ("Boundary Condition Tests",
                       Hale_Tests.Boundaries.Run_All_Boundary_Tests'Access);
            Run_Suite ("Periodic Orbit Tests",
                       Hale_Tests.Periodic_Orbits.Run_All_Periodic_Orbit_Tests'Access);

         when Vallado =>
            Run_Suite ("Vallado Reference Tests",
                       Hale_Tests.Vallado.Run_All_Vallado_Tests'Access);

         when Edge_Cases =>
            Run_Suite ("Edge Case Tests",
                       Hale_Tests.Edge_Cases.Run_All_Edge_Case_Tests'Access);

         when Negative =>
            Run_Suite ("Negative Input Tests",
                       Hale_Tests.Negative.Run_All_Negative_Tests'Access);

         when Exception_Paths =>
            Run_Suite ("Exception Path Tests",
                       Hale_Tests.Exceptions.Run_All_Exception_Tests'Access);

         when Boundaries =>
            Run_Suite ("Boundary Condition Tests",
                       Hale_Tests.Boundaries.Run_All_Boundary_Tests'Access);

         when Periodic_Orbits =>
            Run_Suite ("Periodic Orbit Tests",
                       Hale_Tests.Periodic_Orbits.Run_All_Periodic_Orbit_Tests'Access);
      end case;
   end Run_Tests;

   ---------------------------------------------------------------------------
   --  Print summary with timing information
   ---------------------------------------------------------------------------
   procedure Print_Summary is
      use type Cal.Time;
      Duration_Sec : constant Duration := Results.End_Time - Results.Start_Time;
   begin
      IO.New_Line;
      IO.Put_Line ("==========================================================");
      IO.Put_Line ("  Coverage Test Summary");
      IO.Put_Line ("==========================================================");
      IO.Put_Line ("  Execution Time: " & Duration'Image (Duration_Sec) & " seconds");
      IO.Put_Line ("  Failed Suites:  " & Natural'Image (Results.Failed_Tests));
      IO.Put_Line ("==========================================================");

      if Results.Failed_Tests = 0 then
         IO.Put_Line ("  All test suites completed successfully.");
         IO.Put_Line ("  Ready for coverage analysis.");
      else
         IO.Put_Line ("  Some test suites failed - review results.");
      end if;

      IO.New_Line;
      IO.Put_Line ("Next Steps:");
      IO.Put_Line ("  1. Run: gnatcov coverage -P coverage.gpr --level=stmt+decision");
      IO.Put_Line ("  2. View: coverage/decision/index.html");
      IO.Put_Line ("==========================================================");
   end Print_Summary;

   ---------------------------------------------------------------------------
   --  Generate JUnit XML output for CI integration
   ---------------------------------------------------------------------------
   procedure Generate_JUnit_XML is
      XML_File : IO.File_Type;
      Filename : constant String := "coverage/test-results.xml";
   begin
      if not Generate_XML then
         return;
      end if;

      --  Ensure coverage directory exists
      if not Dir.Exists ("coverage") then
         Dir.Create_Directory ("coverage");
      end if;

      IO.Create (XML_File, IO.Out_File, Filename);

      IO.Put_Line (XML_File, "<?xml version=""1.0"" encoding=""UTF-8""?>");
      IO.Put_Line (XML_File, "<testsuites>");
      IO.Put_Line (XML_File, "  <testsuite name=""HALE Coverage Tests"" " &
                   "tests=""6"" failures=""" &
                   Natural'Image (Results.Failed_Tests) & """>");

      --  Individual test suite results would be added here
      --  For now, just summary

      IO.Put_Line (XML_File, "  </testsuite>");
      IO.Put_Line (XML_File, "</testsuites>");

      IO.Close (XML_File);

      if Verbose then
         IO.Put_Line ("JUnit XML written to: " & Filename);
      end if;
   end Generate_JUnit_XML;

begin
   --  Parse command line
   Parse_Arguments;

   --  Print banner
   Print_Banner;

   --  Record start time
   Results.Start_Time := Cal.Clock;

   --  Run tests
   Run_Tests;

   --  Record end time
   Results.End_Time := Cal.Clock;

   --  Print summary
   Print_Summary;

   --  Generate XML if requested
   Generate_JUnit_XML;

   --  Set exit status
   if Results.Failed_Tests > 0 then
      CL.Set_Exit_Status (CL.Failure);
   else
      CL.Set_Exit_Status (CL.Success);
   end if;

end Test_Driver_Coverage;
