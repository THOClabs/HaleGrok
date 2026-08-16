-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Performance Benchmarks
-------------------------------------------------------------------------------
-- Measures execution time of critical functions to validate performance
-- targets specified in the implementation plan:
--   - Hohmann transfer: < 100 ns
--   - Lambert single solve: < 10 us
--   - Lambert multi-rev: < 50 us
--   - Plane change: < 50 ns
--   - Bielliptic: < 200 ns
--
-- Uses Ada.Real_Time for high-precision timing measurements.
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with Hale_Orbital.Types;      use Hale_Orbital.Types;
with Hale_Orbital.Constants;  use Hale_Orbital.Constants;
with Hale_Orbital.Maneuvers;  use Hale_Orbital.Maneuvers;
with Hale_Orbital.Lambert;    use Hale_Orbital.Lambert;

procedure Performance_Benchmarks is

   package IO renames Ada.Text_IO;

   --  Number of iterations for averaging
   Iterations : constant := 10_000;
   Warmup_Iterations : constant := 1_000;

   --  Timing helper
   function Nanoseconds_Per_Call (Start_Time : Time;
                                   End_Time   : Time;
                                   Num_Calls  : Positive) return Duration is
      Elapsed : constant Time_Span := End_Time - Start_Time;
   begin
      return To_Duration (Elapsed) / Duration (Num_Calls);
   end Nanoseconds_Per_Call;

   procedure Print_Result (Name : String;
                           Avg_Time_Ns : Duration;
                           Target_Ns : Duration) is
      Time_Ns : constant Long_Float := Long_Float (Avg_Time_Ns) * 1.0e9;
      Target : constant Long_Float := Long_Float (Target_Ns) * 1.0e9;
      Pass : constant Boolean := Avg_Time_Ns <= Target_Ns;
   begin
      IO.Put ("  " & Name & ": ");
      IO.Put (Long_Float'Image (Time_Ns));
      IO.Put (" ns (target: ");
      IO.Put (Long_Float'Image (Target));
      IO.Put (" ns) ");
      if Pass then
         IO.Put_Line ("[PASS]");
      else
         IO.Put_Line ("[NEEDS OPTIMIZATION]");
      end if;
   end Print_Result;

   ---------------------------------------------------------------------------
   -- Maneuvers Benchmarks
   ---------------------------------------------------------------------------

   procedure Benchmark_Maneuvers is
      Start_Time, End_Time : Time;
      Result : Hohmann_Result;
      Bielliptic_Res : Bielliptic_Result;
      DV : Velocity_Km_S;
      Avg_Time : Duration;

      --  Test parameters
      R_LEO : constant Distance_Km := Distance_Km (Real (R_Earth) + 200.0);
      R_GEO_Val : constant Distance_Km := 42164.0;
      R_High : constant Distance_Km := 100000.0;
      R_Int : constant Distance_Km := 200000.0;
      Delta_I : constant Angle_Radians := Angle_Radians (28.5 * Deg_To_Rad);
      V_Test : constant Velocity_Km_S := 7.5;

   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Maneuvers Package Benchmarks");
      IO.Put_Line ("=========================================");

      --  Warmup
      for I in 1 .. Warmup_Iterations loop
         Result := Hohmann_Transfer (R_LEO, R_GEO_Val, Mu_Earth);
      end loop;

      -------------------------------------------------------------------------
      --  Hohmann Transfer (Target: < 100 ns)
      -------------------------------------------------------------------------
      Start_Time := Clock;
      for I in 1 .. Iterations loop
         Result := Hohmann_Transfer (R_LEO, R_GEO_Val, Mu_Earth);
      end loop;
      End_Time := Clock;
      Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Iterations);
      Print_Result ("Hohmann_Transfer", Avg_Time, Duration (100.0e-9));

      -------------------------------------------------------------------------
      --  Hohmann Delta-V1 (Target: < 50 ns)
      -------------------------------------------------------------------------
      Start_Time := Clock;
      for I in 1 .. Iterations loop
         DV := Hohmann_Delta_V1 (R_LEO, R_GEO_Val, Mu_Earth);
      end loop;
      End_Time := Clock;
      Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Iterations);
      Print_Result ("Hohmann_Delta_V1", Avg_Time, Duration (50.0e-9));

      -------------------------------------------------------------------------
      --  Bielliptic Transfer (Target: < 200 ns)
      -------------------------------------------------------------------------
      Start_Time := Clock;
      for I in 1 .. Iterations loop
         Bielliptic_Res := Bielliptic_Transfer (R_LEO, R_High, R_Int, Mu_Earth);
      end loop;
      End_Time := Clock;
      Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Iterations);
      Print_Result ("Bielliptic_Transfer", Avg_Time, Duration (200.0e-9));

      -------------------------------------------------------------------------
      --  Simple Plane Change (Target: < 50 ns)
      -------------------------------------------------------------------------
      Start_Time := Clock;
      for I in 1 .. Iterations loop
         DV := Simple_Plane_Change (Delta_I, V_Test);
      end loop;
      End_Time := Clock;
      Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Iterations);
      Print_Result ("Simple_Plane_Change", Avg_Time, Duration (50.0e-9));

      -------------------------------------------------------------------------
      --  Phasing Delta-V (Target: < 100 ns)
      -------------------------------------------------------------------------
      Start_Time := Clock;
      for I in 1 .. Iterations loop
         DV := Phasing_Delta_V (R_LEO, Delta_I, 1, Mu_Earth);
      end loop;
      End_Time := Clock;
      Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Iterations);
      Print_Result ("Phasing_Delta_V", Avg_Time, Duration (100.0e-9));

      -------------------------------------------------------------------------
      --  Escape Delta-V (Target: < 50 ns)
      -------------------------------------------------------------------------
      Start_Time := Clock;
      for I in 1 .. Iterations loop
         DV := Escape_Delta_V (R_LEO, Mu_Earth);
      end loop;
      End_Time := Clock;
      Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Iterations);
      Print_Result ("Escape_Delta_V", Avg_Time, Duration (50.0e-9));

      IO.New_Line;
   end Benchmark_Maneuvers;

   ---------------------------------------------------------------------------
   -- Lambert Benchmarks
   ---------------------------------------------------------------------------

   procedure Benchmark_Lambert is
      Start_Time, End_Time : Time;
      Result : Lambert_Result;
      Multi_Result : Lambert_Solution_Array (0 .. 10);
      Avg_Time : Duration;

      --  Test parameters (Earth orbit intercept)
      R1 : constant Position_Vector := (7000.0, 0.0, 0.0);
      R2 : constant Position_Vector := (0.0, 10000.0, 0.0);
      Tof_Short : constant Time_Seconds := 3600.0;   -- 1 hour
      Tof_Long : constant Time_Seconds := 36000.0;   -- 10 hours (allows multi-rev)

      Lambert_Iterations : constant := 1_000;  -- Fewer iterations for slower function

   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Lambert Solver Benchmarks");
      IO.Put_Line ("=========================================");

      --  Warmup
      for I in 1 .. 100 loop
         Result := Solve_Lambert (R1, R2, Tof_Short, Mu_Earth);
      end loop;

      -------------------------------------------------------------------------
      --  Single-Revolution Lambert (Target: < 10 us)
      -------------------------------------------------------------------------
      Start_Time := Clock;
      for I in 1 .. Lambert_Iterations loop
         Result := Solve_Lambert (R1, R2, Tof_Short, Mu_Earth);
      end loop;
      End_Time := Clock;
      Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Lambert_Iterations);
      Print_Result ("Solve_Lambert (single)", Avg_Time, Duration (10.0e-6));

      -------------------------------------------------------------------------
      --  Lambert with Long-Way (Target: < 10 us)
      -------------------------------------------------------------------------
      Start_Time := Clock;
      for I in 1 .. Lambert_Iterations loop
         Result := Solve_Lambert (R1, R2, Tof_Short, Mu_Earth, Long_Way => True);
      end loop;
      End_Time := Clock;
      Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Lambert_Iterations);
      Print_Result ("Solve_Lambert (long-way)", Avg_Time, Duration (10.0e-6));

      -------------------------------------------------------------------------
      --  Multi-Revolution Lambert (Target: < 50 us)
      -------------------------------------------------------------------------
      Start_Time := Clock;
      for I in 1 .. Lambert_Iterations / 10 loop
         declare
            Res : constant Lambert_Solution_Array :=
               Solve_Lambert_Multi (R1, R2, Tof_Long, Mu_Earth, Max_Revs => 2);
         begin
            null;  -- Just measure execution time
         end;
      end loop;
      End_Time := Clock;
      Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Lambert_Iterations / 10);
      Print_Result ("Solve_Lambert_Multi (2 rev)", Avg_Time, Duration (50.0e-6));

      -------------------------------------------------------------------------
      --  Transfer Angle (Target: < 100 ns)
      -------------------------------------------------------------------------
      Start_Time := Clock;
      for I in 1 .. Iterations loop
         declare
            Angle : constant Angle_Radians := Transfer_Angle (R1, R2);
         begin
            null;
         end;
      end loop;
      End_Time := Clock;
      Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Iterations);
      Print_Result ("Transfer_Angle", Avg_Time, Duration (100.0e-9));

      -------------------------------------------------------------------------
      --  Is_Degenerate_Transfer (Target: < 50 ns)
      -------------------------------------------------------------------------
      Start_Time := Clock;
      for I in 1 .. Iterations loop
         declare
            Is_Degen : constant Boolean := Is_Degenerate_Transfer (R1, R2);
         begin
            null;
         end;
      end loop;
      End_Time := Clock;
      Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Iterations);
      Print_Result ("Is_Degenerate_Transfer", Avg_Time, Duration (50.0e-9));

      -------------------------------------------------------------------------
      --  Departure Delta-V (Target: < 50 ns)
      -------------------------------------------------------------------------
      Result := Solve_Lambert (R1, R2, Tof_Short, Mu_Earth);
      declare
         V_Initial : constant Velocity_Vector := (0.0, 7.5, 0.0);
      begin
         Start_Time := Clock;
         for I in 1 .. Iterations loop
            declare
               DV : constant Velocity_Km_S := Departure_Delta_V (V_Initial, Result);
            begin
               null;
            end;
         end loop;
         End_Time := Clock;
         Avg_Time := Nanoseconds_Per_Call (Start_Time, End_Time, Iterations);
         Print_Result ("Departure_Delta_V", Avg_Time, Duration (50.0e-9));
      end;

      IO.New_Line;
   end Benchmark_Lambert;

   ---------------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------------

   procedure Print_Summary is
   begin
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Benchmark Summary");
      IO.Put_Line ("=========================================");
      IO.Put_Line ("  Iterations per test: " & Integer'Image (Iterations));
      IO.Put_Line ("  Warmup iterations:   " & Integer'Image (Warmup_Iterations));
      IO.Put_Line ("");
      IO.Put_Line ("  Performance Targets (from plan):");
      IO.Put_Line ("    Hohmann transfer:  < 100 ns");
      IO.Put_Line ("    Bielliptic:        < 200 ns");
      IO.Put_Line ("    Plane change:      < 50 ns");
      IO.Put_Line ("    Lambert single:    < 10 us");
      IO.Put_Line ("    Lambert multi-rev: < 50 us");
      IO.Put_Line ("");
      IO.Put_Line ("  Note: Actual performance depends on:");
      IO.Put_Line ("    - Compiler optimization level (-O2, -O3)");
      IO.Put_Line ("    - CPU architecture and cache behavior");
      IO.Put_Line ("    - Inlining effectiveness");
      IO.Put_Line ("=========================================");
   end Print_Summary;

begin
   IO.Put_Line ("");
   IO.Put_Line ("=========================================");
   IO.Put_Line ("  HALE Orbital Mechanics");
   IO.Put_Line ("  Performance Benchmark Suite");
   IO.Put_Line ("=========================================");
   IO.New_Line;

   Benchmark_Maneuvers;
   Benchmark_Lambert;
   Print_Summary;

end Performance_Benchmarks;
