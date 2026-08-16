-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Python Oracle Cross-Validation Suite Body
-------------------------------------------------------------------------------
-- Tolerance rationale (see also DEC-009):
--  * Lagrange x/y/Jacobi: abs 1.0e-6.  The Ada and Python predefined
--    systems derive their mass ratios from slightly different source
--    constants (rel ~1.4e-7), which shifts collinear points by ~1e-9;
--    both Newton solvers are far tighter than 1e-6.
--  * Trajectory endpoints: abs 1.0e-4 (position), 1.0e-3 (velocity) in
--    normalized units.  The l1_lyapunov arc rides an unstable orbit that
--    amplifies integrator differences by ~2 orders of magnitude over
--    t = 2.0; the Ada RK45 error control and SciPy rtol=1e-12 agree to
--    much better than this on the stable arcs.
--  * Floquet: the monodromy is rebuilt with the same fixed STM step the
--    oracle used (1e-4), so the dominant multiplier matches to rel 1e-4;
--    the trivial pair is a defective Jordan block where |lambda-1| is
--    ~sqrt of the sigma residual, hence abs 1e-3 there.
-------------------------------------------------------------------------------

with Ada.Text_IO;
with Ada.Directories;
with Hale_Tests.Runner;       use Hale_Tests.Runner;
with Hale_Orbital.Types;      use Hale_Orbital.Types;
with Hale_Orbital.Threebody;  use Hale_Orbital.Threebody;

package body Hale_Tests.Oracle is

   package IO renames Ada.Text_IO;

   Data_Dir : constant String := "validation/data/";

   Max_Fields : constant := 20;
   type Field_Array is array (1 .. Max_Fields) of Real;

   --  Simple numeric CSV row parser: fills Values(1 .. Count) with the
   --  numeric fields of Line, skipping the first Skip label fields (the
   --  label text of field 1 is returned through Label when Skip > 0).
   procedure Parse_Numeric (Line   : String;
                            Skip   : Natural;
                            Label  : out String;
                            L_Last : out Natural;
                            Values : out Field_Array;
                            Count  : out Natural) is
      Pos   : Positive := Line'First;
      Start : Positive;
      Field : Natural := 0;
   begin
      Count := 0;
      L_Last := Label'First - 1;
      while Pos <= Line'Last loop
         Start := Pos;
         while Pos <= Line'Last and then Line (Pos) /= ',' loop
            Pos := Pos + 1;
         end loop;
         Field := Field + 1;
         declare
            Text : constant String := Line (Start .. Pos - 1);
         begin
            if Field <= Skip then
               if Field = 1 then
                  L_Last := Label'First + Text'Length - 1;
                  Label (Label'First .. L_Last) := Text;
               end if;
            else
               Count := Count + 1;
               Values (Count) := Real'Value (Text);
            end if;
         end;
         Pos := Pos + 1;  --  skip the comma
      end loop;
   end Parse_Numeric;

   --  True for comment/header lines that carry no data
   function Is_Data_Line (Line : String) return Boolean is
   begin
      if Line'Length = 0 then
         return False;
      end if;
      if Line (Line'First) = '#' then
         return False;
      end if;
      --  The column-header line starts with a letter but its first field
      --  never parses as a number; data lines are distinguished by caller
      --  context (first non-comment line is always the header).
      return True;
   end Is_Data_Line;

   ---------------------------------------------------------------------------
   -- Lagrange points + Jacobi constants vs lagrange_points.csv
   ---------------------------------------------------------------------------

   procedure Test_Lagrange_Oracle is
      File : IO.File_Type;
      Header_Skipped : Boolean := False;
      Rows : Natural := 0;
      Pos_Tol : constant Real := 1.0e-6;
   begin
      Start_Suite ("Python oracle: Lagrange points");
      IO.Open (File, IO.In_File, Data_Dir & "lagrange_points.csv");
      while not IO.End_Of_File (File) loop
         declare
            Line : constant String := IO.Get_Line (File);
         begin
            if Is_Data_Line (Line) then
               if not Header_Skipped then
                  Header_Skipped := True;
               else
                  declare
                     Label  : String (1 .. 64);
                     L_Last : Natural;
                     V      : Field_Array;
                     N      : Natural;
                  begin
                     --  system,point,x,y,jacobi  (2 label fields)
                     Parse_Numeric (Line, 2, Label, L_Last, V, N);
                     declare
                        Sys_Name : constant String := Label (1 .. L_Last);
                        --  Second label field (L1..L5) recovered from the
                        --  raw line: it sits between the first and second
                        --  commas.
                        C1 : Natural := Line'First;
                        C2 : Natural;
                     begin
                        while Line (C1) /= ',' loop
                           C1 := C1 + 1;
                        end loop;
                        C2 := C1 + 1;
                        while Line (C2) /= ',' loop
                           C2 := C2 + 1;
                        end loop;
                        --  The oracle covers more systems than the Ada
                        --  library defines; compare only the shared three.
                        if Sys_Name = "earth-moon"
                           or else Sys_Name = "sun-earth"
                           or else Sys_Name = "sun-jupiter"
                        then
                           declare
                              Point : constant Lagrange_Point :=
                                 Lagrange_Point'Value
                                    (Line (C1 + 1 .. C2 - 1));
                              System : constant Threebody_System :=
                                 (if Sys_Name = "earth-moon"
                                  then Earth_Moon_System
                                  elsif Sys_Name = "sun-earth"
                                  then Sun_Earth_System
                                  else Sun_Jupiter_System);
                              R : constant Lagrange_Result :=
                                 Compute_Lagrange_Point (System, Point);
                              C_Ada : constant Real := Jacobi_Constant
                                 ((X => R.X, Y => R.Y, Z => 0.0,
                                   VX => 0.0, VY => 0.0, VZ => 0.0),
                                  System.Mass_Ratio);
                           begin
                              Rows := Rows + 1;
                              Run_Test (Sys_Name & " " &
                                        Lagrange_Point'Image (Point) &
                                        " x/y/C",
                                        R.Converged
                                        and abs (R.X - V (1)) < Pos_Tol
                                        and abs (R.Y - V (2)) < Pos_Tol
                                        and abs (C_Ada - V (3)) < Pos_Tol);
                           end;
                        end if;
                     end;
                  end;
               end if;
            end if;
         end;
      end loop;
      IO.Close (File);
      Run_Test ("oracle compared 15 shared Lagrange rows", Rows = 15);
      End_Suite;
   exception
      when others =>
         if IO.Is_Open (File) then
            IO.Close (File);
         end if;
         Run_Test ("lagrange oracle readable (run from repo root?)", False);
         End_Suite;
   end Test_Lagrange_Oracle;

   ---------------------------------------------------------------------------
   -- Trajectory endpoints vs trajectories.csv (adaptive RK45)
   ---------------------------------------------------------------------------

   procedure Test_Trajectory_Oracle is
      File : IO.File_Type;
      Header_Skipped : Boolean := False;
      Rows : Natural := 0;
      Pos_Tol : constant Real := 1.0e-4;
      Vel_Tol : constant Real := 1.0e-3;
   begin
      Start_Suite ("Python oracle: RK45 trajectory endpoints");
      IO.Open (File, IO.In_File, Data_Dir & "trajectories.csv");
      while not IO.End_Of_File (File) loop
         declare
            Line : constant String := IO.Get_Line (File);
         begin
            if Is_Data_Line (Line) then
               if not Header_Skipped then
                  Header_Skipped := True;
               else
                  declare
                     Label  : String (1 .. 64);
                     L_Last : Natural;
                     V      : Field_Array;
                     N      : Natural;
                  begin
                     --  case,mu,x0..vz0,t_final,xf..vzf,jacobi_drift
                     Parse_Numeric (Line, 1, Label, L_Last, V, N);
                     Rows := Rows + 1;
                     declare
                        Mu : constant Real := V (1);
                        S0 : constant Normalized_State :=
                           (X => V (2), Y => V (3), Z => V (4),
                            VX => V (5), VY => V (6), VZ => V (7));
                        T_Final : constant Real := V (8);
                        SF : constant Normalized_State :=
                           Propagate (S0, Mu, T_Final,
                                      Step_Size => 0.01, Method => RK45);
                        C0 : constant Real := Jacobi_Constant (S0, Mu);
                        CF : constant Real := Jacobi_Constant (SF, Mu);
                     begin
                        Run_Test ("traj " & Label (1 .. L_Last) & ": endpoint",
                                  abs (SF.X - V (9)) < Pos_Tol
                                  and abs (SF.Y - V (10)) < Pos_Tol
                                  and abs (SF.Z - V (11)) < Pos_Tol
                                  and abs (SF.VX - V (12)) < Vel_Tol
                                  and abs (SF.VY - V (13)) < Vel_Tol
                                  and abs (SF.VZ - V (14)) < Vel_Tol);
                        Run_Test ("traj " & Label (1 .. L_Last) &
                                  ": Ada Jacobi drift < 1e-8",
                                  abs (CF - C0) < 1.0e-8);
                     end;
                  end;
               end if;
            end if;
         end;
      end loop;
      IO.Close (File);
      Run_Test ("trajectories.csv has 4 rows", Rows = 4);
      End_Suite;
   exception
      when others =>
         if IO.Is_Open (File) then
            IO.Close (File);
         end if;
         Run_Test ("trajectory oracle readable (run from repo root?)", False);
         End_Suite;
   end Test_Trajectory_Oracle;

   ---------------------------------------------------------------------------
   -- Floquet multipliers vs floquet.csv
   ---------------------------------------------------------------------------

   procedure Test_Floquet_Oracle is
      File : IO.File_Type;
      Header_Skipped : Boolean := False;
   begin
      Start_Suite ("Python oracle: Floquet multipliers");
      IO.Open (File, IO.In_File, Data_Dir & "floquet.csv");
      while not IO.End_Of_File (File) loop
         declare
            Line : constant String := IO.Get_Line (File);
         begin
            if Is_Data_Line (Line) then
               if not Header_Skipped then
                  Header_Skipped := True;
               else
                  declare
                     Label  : String (1 .. 8);
                     L_Last : Natural;
                     V      : Field_Array;
                     N      : Natural;
                  begin
                     --  mu,x0,vy0,period,ev1_re,ev1_im,...,ev6_re,ev6_im
                     Parse_Numeric (Line, 0, Label, L_Last, V, N);
                     declare
                        Mu     : constant Real := V (1);
                        S0     : constant Normalized_State :=
                           (X => V (2), Y => 0.0, Z => 0.0,
                            VX => 0.0, VY => V (3), VZ => 0.0);
                        Period : constant Real := V (4);
                        --  Same fixed STM step the oracle used (1e-4)
                        M : constant Matrix_6x6 :=
                           Compute_Monodromy (S0, Mu, Period, 1.0e-4);
                        F : constant Floquet_Result := Analyze_Floquet (M);
                        Ev1 : constant Real := V (5);   -- dominant (real)
                        --  Oracle rows are magnitude-sorted; the smallest
                        --  is the reciprocal of the dominant.
                        Ev_Min : constant Real := V (15);
                        Trivial_Found : Boolean := False;
                        Mid_Found     : Boolean := False;
                     begin
                        Run_Test ("floquet: monodromy passes validity checks",
                                  F.Valid);
                        Run_Test ("floquet: dominant multiplier matches oracle",
                                  abs (F.Max_Multiplier - Ev1)
                                     < 1.0e-4 * Ev1);
                        for I in F.Multipliers'Range loop
                           declare
                              Re : constant Real := F.Multipliers (I).Re;
                              Im : constant Real := F.Multipliers (I).Im;
                           begin
                              if abs (Re - 1.0) < 1.0e-3
                                 and abs (Im) < 1.0e-3
                              then
                                 Trivial_Found := True;
                              end if;
                              --  middle real pair member (oracle ev2)
                              if abs (Im) < 1.0e-6
                                 and then abs (Re - V (7)) <
                                    1.0e-3 * abs (V (7)) + 1.0e-6
                              then
                                 Mid_Found := True;
                              end if;
                           end;
                        end loop;
                        Run_Test ("floquet: trivial unit pair present",
                                  Trivial_Found);
                        Run_Test ("floquet: middle real multiplier matches",
                                  Mid_Found);
                        Run_Test ("floquet: reciprocal of dominant matches",
                                  abs (1.0 / F.Max_Multiplier - Ev_Min)
                                     < 1.0e-4 * Ev_Min + 1.0e-9);
                     end;
                  end;
               end if;
            end if;
         end;
      end loop;
      IO.Close (File);
      End_Suite;
   exception
      when others =>
         if IO.Is_Open (File) then
            IO.Close (File);
         end if;
         Run_Test ("floquet oracle readable (run from repo root?)", False);
         End_Suite;
   end Test_Floquet_Oracle;

   ---------------------------------------------------------------------------

   procedure Run_All_Oracle_Tests is
   begin
      if not Ada.Directories.Exists (Data_Dir) then
         Start_Suite ("Python oracle cross-validation");
         Run_Test ("validation/data present (run from repo root)", False);
         End_Suite;
         return;
      end if;
      Test_Lagrange_Oracle;
      Test_Trajectory_Oracle;
      Test_Floquet_Oracle;
   end Run_All_Oracle_Tests;

end Hale_Tests.Oracle;
