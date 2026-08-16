-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Numerical Propagation Package Body
-------------------------------------------------------------------------------

with Ada.Exceptions;
with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Vectors; use Hale_Orbital.Vectors;

package body Hale_Orbital.Propagation is
   --  Spec is not SPARK-mode-annotated, so the body cannot toggle it.
   --  When the Propagation spec is brought into SPARK, re-add
   --  `with SPARK_Mode => Off` here.

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   ---------------------------------------------------------------------------
   -- Two-Body Force Model Implementation
   ---------------------------------------------------------------------------

   overriding
   function Acceleration (Model : Two_Body_Model;
                          T     : Time_Seconds;
                          State : State_Vector) return Vector_3D is
      pragma Unreferenced (T);
      R : constant Vector_3D := State.Position;
      R_Mag : constant Real := Magnitude (R);
      R_Mag_Cubed : constant Real := R_Mag ** 3;
      Mu_Val : constant Real := Real (Model.Mu);
   begin
      if R_Mag < 1.0e-10 then
         raise Physical_Error with "Position magnitude too small";
      end if;

      --  a = -mu * r / |r|^3
      return (-Mu_Val / R_Mag_Cubed) * R;
   end Acceleration;

   ---------------------------------------------------------------------------
   -- J2 Perturbation Model Implementation
   ---------------------------------------------------------------------------

   overriding
   function Acceleration (Model : J2_Model;
                          T     : Time_Seconds;
                          State : State_Vector) return Vector_3D is
      pragma Unreferenced (T);

      R : constant Vector_3D := State.Position;
      X : constant Real := R (1);
      Y : constant Real := R (2);
      Z : constant Real := R (3);

      R_Mag : constant Real := Magnitude (R);
      R_Sq : constant Real := R_Mag ** 2;
      R_Cubed : constant Real := R_Mag ** 3;
      R_Fifth : constant Real := R_Mag ** 5;

      Mu_Val : constant Real := Real (Model.Mu);
      Re : constant Real := Real (Model.R_Eq);
      J2_Val : constant Real := Model.J2;

      --  J2 perturbation factor
      Factor : constant Real := (3.0 / 2.0) * J2_Val * Mu_Val * (Re ** 2) / R_Fifth;
      Z_R_Sq : constant Real := (Z / R_Mag) ** 2;

      --  Acceleration components
      A_Two_Body : Vector_3D;
      A_J2 : Vector_3D;

   begin
      if R_Mag < 1.0e-10 then
         raise Physical_Error with "Position magnitude too small";
      end if;

      --  Two-body acceleration
      A_Two_Body := (-Mu_Val / R_Cubed) * R;

      --  J2 perturbation acceleration
      A_J2 (1) := Factor * X * (5.0 * Z_R_Sq - 1.0);
      A_J2 (2) := Factor * Y * (5.0 * Z_R_Sq - 1.0);
      A_J2 (3) := Factor * Z * (5.0 * Z_R_Sq - 3.0);

      return A_Two_Body + A_J2;
   end Acceleration;

   ---------------------------------------------------------------------------
   -- State Derivative
   ---------------------------------------------------------------------------

   function State_Derivative (State : State_Vector;
                              Accel : Vector_3D) return State_Vector is
   begin
      return (Position => State.Velocity,
              Velocity => Accel);
   end State_Derivative;

   ---------------------------------------------------------------------------
   -- RK4 Single Step
   ---------------------------------------------------------------------------

   procedure RK4_Step (State : in out State_Vector;
                       T     : Time_Seconds;
                       H     : Time_Seconds;
                       Model : Force_Model'Class) is
      H_Val : constant Real := Real (H);
      Half_H : constant Real := H_Val / 2.0;

      K1, K2, K3, K4 : State_Vector;
      Temp_State : State_Vector;
      A1, A2, A3, A4 : Vector_3D;

   begin
      --  k1 = f(t, y)
      A1 := Acceleration (Model, T, State);
      K1 := State_Derivative (State, A1);

      --  k2 = f(t + h/2, y + h/2 * k1)
      Temp_State.Position := State.Position + Half_H * K1.Position;
      Temp_State.Velocity := State.Velocity + Half_H * K1.Velocity;
      A2 := Acceleration (Model, T + Time_Seconds (Half_H), Temp_State);
      K2 := State_Derivative (Temp_State, A2);

      --  k3 = f(t + h/2, y + h/2 * k2)
      Temp_State.Position := State.Position + Half_H * K2.Position;
      Temp_State.Velocity := State.Velocity + Half_H * K2.Velocity;
      A3 := Acceleration (Model, T + Time_Seconds (Half_H), Temp_State);
      K3 := State_Derivative (Temp_State, A3);

      --  k4 = f(t + h, y + h * k3)
      Temp_State.Position := State.Position + H_Val * K3.Position;
      Temp_State.Velocity := State.Velocity + H_Val * K3.Velocity;
      A4 := Acceleration (Model, T + H, Temp_State);
      K4 := State_Derivative (Temp_State, A4);

      --  y_new = y + h/6 * (k1 + 2*k2 + 2*k3 + k4)
      State.Position := State.Position +
         (H_Val / 6.0) * (K1.Position + 2.0 * K2.Position +
                          2.0 * K3.Position + K4.Position);
      State.Velocity := State.Velocity +
         (H_Val / 6.0) * (K1.Velocity + 2.0 * K2.Velocity +
                          2.0 * K3.Velocity + K4.Velocity);
   end RK4_Step;

   ---------------------------------------------------------------------------
   -- RK4 Fixed-Step Propagator
   ---------------------------------------------------------------------------

   function Propagate_RK4 (Initial  : State_Vector;
                           T_Start  : Time_Seconds;
                           T_End    : Time_Seconds;
                           Step     : Time_Seconds;
                           Model    : Force_Model'Class) return State_Vector is
      State : State_Vector := Initial;
      T : Time_Seconds := T_Start;
      H : Time_Seconds := Step;
      Direction : constant Real := (if Real (T_End) >= Real (T_Start) then 1.0 else -1.0);

   begin
      --  Adjust step direction
      H := Time_Seconds (Direction * abs (Real (Step)));

      --  Integrate
      while (Direction > 0.0 and then Real (T) < Real (T_End)) or else
            (Direction < 0.0 and then Real (T) > Real (T_End)) loop

         --  Adjust final step to hit T_End exactly
         if abs (Real (T_End) - Real (T)) < abs (Real (H)) then
            H := T_End - T;
         end if;

         RK4_Step (State, T, H, Model);
         T := T + H;
      end loop;

      return State;
   end Propagate_RK4;

   function Propagate_RK4 (Initial : State_Vector;
                           T_Start : Time_Seconds;
                           T_End   : Time_Seconds;
                           Config  : Propagator_Config;
                           Model   : Force_Model'Class) return Propagation_Result is
      Result : Propagation_Result;
      State : State_Vector := Initial;
      T : Time_Seconds := T_Start;
      H : Time_Seconds := Config.Step_Size;
      Direction : constant Real := (if Real (T_End) >= Real (T_Start) then 1.0 else -1.0);
      Steps : Natural := 0;

   begin
      Result.Message := (others => ' ');
      H := Time_Seconds (Direction * abs (Real (H)));

      while (Direction > 0.0 and then Real (T) < Real (T_End)) or else
            (Direction < 0.0 and then Real (T) > Real (T_End)) loop

         if Steps >= Config.Max_Steps then
            Result.Final_State := State;
            Result.Steps_Used := Steps;
            Result.Success := False;
            Result.Message (1 .. 23) := "Max steps exceeded     ";
            return Result;
         end if;

         if abs (Real (T_End) - Real (T)) < abs (Real (H)) then
            H := T_End - T;
         end if;

         RK4_Step (State, T, H, Model);
         T := T + H;
         Steps := Steps + 1;
      end loop;

      Result.Final_State := State;
      Result.Steps_Used := Steps;
      Result.Success := True;
      Result.Message (1 .. 7) := "Success";

      return Result;
   end Propagate_RK4;

   ---------------------------------------------------------------------------
   -- Embedded Runge-Kutta Infrastructure
   ---------------------------------------------------------------------------
   --  Shared machinery for embedded (adaptive) Runge-Kutta pairs.
   --  A method is defined by its Butcher tableau: nodes C, coupling matrix A,
   --  propagation weights B, and error weights E where E (I) is the difference
   --  between the propagation weights and the embedded solution weights, so
   --  the local error estimate is H * sum (E (I) * K (I)).

   type Node_Array is array (Positive range <>) of Real;
   type Coupling_Matrix is array (Positive range <>, Positive range <>) of Real;
   type Stage_Array is array (Positive range <>) of State_Vector;

   ---------------------------------------------------------------------------
   -- Dormand-Prince 5(4) Tableau (DOPRI5)
   ---------------------------------------------------------------------------
   --  Reference: Dormand & Prince (1980), J. Comp. Appl. Math. 6(1), Table 2.
   --  7 stages; B is the 5th-order row, the embedded 4th-order row B* gives
   --  DP54_E = B - B*.

   DP54_Stages : constant := 7;

   DP54_C : constant Node_Array (1 .. DP54_Stages) :=
      (0.0, 1.0 / 5.0, 3.0 / 10.0, 4.0 / 5.0, 8.0 / 9.0, 1.0, 1.0);

   DP54_A : constant Coupling_Matrix (2 .. DP54_Stages, 1 .. DP54_Stages - 1) :=
      (2 => (1.0 / 5.0, others => 0.0),
       3 => (3.0 / 40.0, 9.0 / 40.0, others => 0.0),
       4 => (44.0 / 45.0, -56.0 / 15.0, 32.0 / 9.0, others => 0.0),
       5 => (19372.0 / 6561.0, -25360.0 / 2187.0, 64448.0 / 6561.0,
             -212.0 / 729.0, others => 0.0),
       6 => (9017.0 / 3168.0, -355.0 / 33.0, 46732.0 / 5247.0,
             49.0 / 176.0, -5103.0 / 18656.0, others => 0.0),
       7 => (35.0 / 384.0, 0.0, 500.0 / 1113.0, 125.0 / 192.0,
             -2187.0 / 6784.0, 11.0 / 84.0));

   --  5th-order propagation weights
   DP54_B : constant Node_Array (1 .. DP54_Stages) :=
      (35.0 / 384.0, 0.0, 500.0 / 1113.0, 125.0 / 192.0,
       -2187.0 / 6784.0, 11.0 / 84.0, 0.0);

   --  Error weights: 5th-order row minus embedded 4th-order row
   --  (B* = 5179/57600, 0, 7571/16695, 393/640, -92097/339200, 187/2100, 1/40)
   DP54_E : constant Node_Array (1 .. DP54_Stages) :=
      (71.0 / 57600.0, 0.0, -71.0 / 16695.0, 71.0 / 1920.0,
       -17253.0 / 339200.0, 22.0 / 525.0, -1.0 / 40.0);

   ---------------------------------------------------------------------------
   -- Fehlberg 7(8) Tableau (RKF78)
   ---------------------------------------------------------------------------
   --  Reference: Fehlberg (1968), NASA TR R-287, Table X.
   --  13 stages; B is the 7th-order row, the embedded 8th-order row B* gives
   --  RKF78_E = B - B* = (41/840) * (K1 + K11 - K12 - K13).

   RKF78_Stages : constant := 13;

   RKF78_C : constant Node_Array (1 .. RKF78_Stages) :=
      (0.0, 2.0 / 27.0, 1.0 / 9.0, 1.0 / 6.0, 5.0 / 12.0, 1.0 / 2.0,
       5.0 / 6.0, 1.0 / 6.0, 2.0 / 3.0, 1.0 / 3.0, 1.0, 0.0, 1.0);

   RKF78_A : constant Coupling_Matrix (2 .. RKF78_Stages, 1 .. RKF78_Stages - 1) :=
      (2  => (2.0 / 27.0, others => 0.0),
       3  => (1.0 / 36.0, 1.0 / 12.0, others => 0.0),
       4  => (1.0 / 24.0, 0.0, 1.0 / 8.0, others => 0.0),
       5  => (5.0 / 12.0, 0.0, -25.0 / 16.0, 25.0 / 16.0, others => 0.0),
       6  => (1.0 / 20.0, 0.0, 0.0, 1.0 / 4.0, 1.0 / 5.0, others => 0.0),
       7  => (-25.0 / 108.0, 0.0, 0.0, 125.0 / 108.0, -65.0 / 27.0,
              125.0 / 54.0, others => 0.0),
       8  => (31.0 / 300.0, 0.0, 0.0, 0.0, 61.0 / 225.0, -2.0 / 9.0,
              13.0 / 900.0, others => 0.0),
       9  => (2.0, 0.0, 0.0, -53.0 / 6.0, 704.0 / 45.0, -107.0 / 9.0,
              67.0 / 90.0, 3.0, others => 0.0),
       10 => (-91.0 / 108.0, 0.0, 0.0, 23.0 / 108.0, -976.0 / 135.0,
              311.0 / 54.0, -19.0 / 60.0, 17.0 / 6.0, -1.0 / 12.0,
              others => 0.0),
       11 => (2383.0 / 4100.0, 0.0, 0.0, -341.0 / 164.0, 4496.0 / 1025.0,
              -301.0 / 82.0, 2133.0 / 4100.0, 45.0 / 82.0, 45.0 / 164.0,
              18.0 / 41.0, others => 0.0),
       12 => (3.0 / 205.0, 0.0, 0.0, 0.0, 0.0, -6.0 / 41.0, -3.0 / 205.0,
              -3.0 / 41.0, 3.0 / 41.0, 6.0 / 41.0, 0.0, 0.0),
       13 => (-1777.0 / 4100.0, 0.0, 0.0, -341.0 / 164.0, 4496.0 / 1025.0,
              -289.0 / 82.0, 2193.0 / 4100.0, 51.0 / 82.0, 33.0 / 164.0,
              12.0 / 41.0, 0.0, 1.0));

   --  7th-order propagation weights
   RKF78_B : constant Node_Array (1 .. RKF78_Stages) :=
      (41.0 / 840.0, 0.0, 0.0, 0.0, 0.0, 34.0 / 105.0, 9.0 / 35.0,
       9.0 / 35.0, 9.0 / 280.0, 9.0 / 280.0, 41.0 / 840.0, 0.0, 0.0);

   --  Error weights: 7th-order row minus embedded 8th-order row
   RKF78_E : constant Node_Array (1 .. RKF78_Stages) :=
      (41.0 / 840.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
       41.0 / 840.0, -41.0 / 840.0, -41.0 / 840.0);

   ---------------------------------------------------------------------------
   -- Generic Embedded RK Step
   ---------------------------------------------------------------------------
   --  Performs one adaptive step of an embedded RK pair defined by (C, A, B, E)
   --  with step size controller exponent Exponent and 0.9 safety factor.
   --  On rejection, H is reduced (scale clamped to [0.1, 0.5]) and State is
   --  unchanged; on acceptance, State is advanced and H adapted for the next
   --  step (scale clamped to [0.1, 2.0]).  H always respects Min/Max_Step.

   procedure Embedded_RK_Step (State     : in out State_Vector;
                               T         : Time_Seconds;
                               H         : in out Time_Seconds;
                               Tolerance : Real;
                               Min_Step  : Time_Seconds;
                               Max_Step  : Time_Seconds;
                               Model     : Force_Model'Class;
                               C         : Node_Array;
                               A         : Coupling_Matrix;
                               B         : Node_Array;
                               E         : Node_Array;
                               Exponent  : Real;
                               Rejected  : out Boolean) is

      N_Stages : constant Positive := C'Length;
      H_Val    : constant Real := Real (H);

      K : Stage_Array (1 .. N_Stages);

      Y_New     : State_Vector;
      Err_Pos   : Vector_3D := (0.0, 0.0, 0.0);
      Err_Vel   : Vector_3D := (0.0, 0.0, 0.0);
      Error_Est : Real;
      Scale     : Real;

   begin
      Rejected := False;

      --  Stage 1
      K (1) := State_Derivative (State, Acceleration (Model, T, State));

      --  Stages 2 .. N: full Butcher coupling
      --  y_i = y + h * sum_{j<i} A (i, j) * k_j
      for I in 2 .. N_Stages loop
         declare
            Sum_Pos : Vector_3D := (0.0, 0.0, 0.0);
            Sum_Vel : Vector_3D := (0.0, 0.0, 0.0);
            Y_Stage : State_Vector;
         begin
            for J in 1 .. I - 1 loop
               if A (I, J) /= 0.0 then
                  Sum_Pos := Sum_Pos + A (I, J) * K (J).Position;
                  Sum_Vel := Sum_Vel + A (I, J) * K (J).Velocity;
               end if;
            end loop;
            Y_Stage.Position := State.Position + H_Val * Sum_Pos;
            Y_Stage.Velocity := State.Velocity + H_Val * Sum_Vel;
            K (I) := State_Derivative
               (Y_Stage,
                Acceleration (Model, T + Time_Seconds (C (I) * H_Val), Y_Stage));
         end;
      end loop;

      --  Propagated (higher-order) solution and embedded error estimate
      declare
         Sum_Pos : Vector_3D := (0.0, 0.0, 0.0);
         Sum_Vel : Vector_3D := (0.0, 0.0, 0.0);
      begin
         for I in 1 .. N_Stages loop
            if B (I) /= 0.0 then
               Sum_Pos := Sum_Pos + B (I) * K (I).Position;
               Sum_Vel := Sum_Vel + B (I) * K (I).Velocity;
            end if;
            if E (I) /= 0.0 then
               Err_Pos := Err_Pos + E (I) * K (I).Position;
               Err_Vel := Err_Vel + E (I) * K (I).Velocity;
            end if;
         end loop;
         Y_New.Position := State.Position + H_Val * Sum_Pos;
         Y_New.Velocity := State.Velocity + H_Val * Sum_Vel;
      end;

      --  Error estimation with relative weighting
      --  Normalize by current state magnitude for scale-independent error
      declare
         Pos_Scale : constant Real := Real'Max (Magnitude (Y_New.Position), 1.0);
         Vel_Scale : constant Real := Real'Max (Magnitude (Y_New.Velocity), 1.0e-6);
         Error_P   : constant Real := abs (H_Val) * Magnitude (Err_Pos);
         Error_V   : constant Real := abs (H_Val) * Magnitude (Err_Vel);
      begin
         Error_Est := Real'Max (Error_P / Pos_Scale, Error_V / Vel_Scale);
      end;

      --  Step size control (safety factor 0.9, exponent per method order)
      if Error_Est > Tolerance and then abs (H_Val) > Real (Min_Step) then
         --  Reject step and reduce step size
         Scale := 0.9 * (Tolerance / Error_Est) ** Exponent;
         Scale := Real'Max (0.1, Real'Min (Scale, 0.5));  -- Limit reduction
         H := Time_Seconds (H_Val * Scale);
         if abs (Real (H)) < Real (Min_Step) then
            H := Time_Seconds ((if H_Val >= 0.0 then 1.0 else -1.0) * Real (Min_Step));
         end if;
         Rejected := True;
      else
         --  Accept step
         State := Y_New;

         --  Adjust step size for next step
         --  Per specification: up to 2x growth, down to 0.1x reduction
         if Error_Est > 0.0 then
            Scale := 0.9 * (Tolerance / Error_Est) ** Exponent;
            Scale := Real'Max (0.1, Real'Min (Scale, 2.0));  -- Per spec: limit to 2x
            H := Time_Seconds (H_Val * Scale);
         end if;

         --  Enforce step size limits
         if abs (Real (H)) > Real (Max_Step) then
            H := Time_Seconds ((if H_Val >= 0.0 then 1.0 else -1.0) * Real (Max_Step));
         end if;
         if abs (Real (H)) < Real (Min_Step) then
            H := Time_Seconds ((if H_Val >= 0.0 then 1.0 else -1.0) * Real (Min_Step));
         end if;
      end if;
   end Embedded_RK_Step;

   ---------------------------------------------------------------------------
   -- DP54 Single Step
   ---------------------------------------------------------------------------
   --  One adaptive Dormand-Prince 5(4) step; controller exponent 1/5

   procedure DP54_Step (State     : in out State_Vector;
                        T         : Time_Seconds;
                        H         : in out Time_Seconds;
                        Tolerance : Real;
                        Min_Step  : Time_Seconds;
                        Max_Step  : Time_Seconds;
                        Model     : Force_Model'Class;
                        Rejected  : out Boolean) is
   begin
      Embedded_RK_Step (State, T, H, Tolerance, Min_Step, Max_Step, Model,
                        DP54_C, DP54_A, DP54_B, DP54_E,
                        Exponent => 1.0 / 5.0,
                        Rejected => Rejected);
   end DP54_Step;

   ---------------------------------------------------------------------------
   -- RKF78 Single Step
   ---------------------------------------------------------------------------
   --  One adaptive Fehlberg 7(8) step; controller exponent 1/8

   procedure RKF78_Step (State     : in out State_Vector;
                         T         : Time_Seconds;
                         H         : in out Time_Seconds;
                         Tolerance : Real;
                         Min_Step  : Time_Seconds;
                         Max_Step  : Time_Seconds;
                         Model     : Force_Model'Class;
                         Rejected  : out Boolean) is
   begin
      Embedded_RK_Step (State, T, H, Tolerance, Min_Step, Max_Step, Model,
                        RKF78_C, RKF78_A, RKF78_B, RKF78_E,
                        Exponent => 1.0 / 8.0,
                        Rejected => Rejected);
   end RKF78_Step;

   ---------------------------------------------------------------------------
   -- Adaptive-Step Propagator Driver
   ---------------------------------------------------------------------------
   --  Shared adaptive integration loop; the method selects the step routine

   type Adaptive_Method is (Method_DP54, Method_RKF78);

   function Propagate_Adaptive (Initial : State_Vector;
                                T_Start : Time_Seconds;
                                T_End   : Time_Seconds;
                                Config  : Propagator_Config;
                                Model   : Force_Model'Class;
                                Method  : Adaptive_Method) return Propagation_Result is
      Result : Propagation_Result;
      State : State_Vector := Initial;
      T : Time_Seconds := T_Start;
      H : Time_Seconds := Config.Step_Size;
      Direction : constant Real := (if Real (T_End) >= Real (T_Start) then 1.0 else -1.0);
      Steps : Natural := 0;
      Rejected : Boolean;

   begin
      Result.Message := (others => ' ');
      H := Time_Seconds (Direction * abs (Real (H)));

      while (Direction > 0.0 and then Real (T) < Real (T_End) - 1.0e-10) or else
            (Direction < 0.0 and then Real (T) > Real (T_End) + 1.0e-10) loop

         if Steps >= Config.Max_Steps then
            Result.Final_State := State;
            Result.Steps_Used := Steps;
            Result.Success := False;
            Result.Message (1 .. 23) := "Max steps exceeded     ";
            return Result;
         end if;

         --  Adjust step to not overshoot
         if abs (Real (T_End) - Real (T)) < abs (Real (H)) then
            H := T_End - T;
         end if;

         --  The step routines advance State by exactly the H they are called
         --  with and then update H to the recommended size for the NEXT
         --  attempt, so time must be advanced by the attempted step size
         declare
            H_Attempt : constant Time_Seconds := H;
         begin
            case Method is
               when Method_DP54 =>
                  DP54_Step (State, T, H, Config.Tolerance,
                             Config.Min_Step, Config.Max_Step, Model, Rejected);
               when Method_RKF78 =>
                  RKF78_Step (State, T, H, Config.Tolerance,
                              Config.Min_Step, Config.Max_Step, Model, Rejected);
            end case;

            if not Rejected then
               T := T + H_Attempt;
            end if;
         end;

         Steps := Steps + 1;
      end loop;

      Result.Final_State := State;
      Result.Steps_Used := Steps;
      Result.Success := True;
      Result.Message (1 .. 7) := "Success";

      return Result;
   end Propagate_Adaptive;

   ---------------------------------------------------------------------------
   -- DP54 Adaptive-Step Propagator (Dormand-Prince 5(4))
   ---------------------------------------------------------------------------

   function Propagate_DP54 (Initial   : State_Vector;
                            T_Start   : Time_Seconds;
                            T_End     : Time_Seconds;
                            Tolerance : Real;
                            Model     : Force_Model'Class) return State_Vector is
      Config : Propagator_Config;
   begin
      Config.Tolerance := Tolerance;
      return Propagate_DP54 (Initial, T_Start, T_End, Config, Model).Final_State;
   end Propagate_DP54;

   function Propagate_DP54 (Initial : State_Vector;
                            T_Start : Time_Seconds;
                            T_End   : Time_Seconds;
                            Config  : Propagator_Config;
                            Model   : Force_Model'Class) return Propagation_Result is
   begin
      return Propagate_Adaptive (Initial, T_Start, T_End, Config, Model, Method_DP54);
   end Propagate_DP54;

   ---------------------------------------------------------------------------
   -- RK78 Adaptive-Step Propagator (Fehlberg 7(8))
   ---------------------------------------------------------------------------

   function Propagate_RK78 (Initial   : State_Vector;
                            T_Start   : Time_Seconds;
                            T_End     : Time_Seconds;
                            Tolerance : Real;
                            Model     : Force_Model'Class) return State_Vector is
      Config : Propagator_Config;
   begin
      Config.Tolerance := Tolerance;
      return Propagate_RK78 (Initial, T_Start, T_End, Config, Model).Final_State;
   end Propagate_RK78;

   function Propagate_RK78 (Initial : State_Vector;
                            T_Start : Time_Seconds;
                            T_End   : Time_Seconds;
                            Config  : Propagator_Config;
                            Model   : Force_Model'Class) return Propagation_Result is
   begin
      return Propagate_Adaptive (Initial, T_Start, T_End, Config, Model, Method_RKF78);
   end Propagate_RK78;

   ---------------------------------------------------------------------------
   -- Trajectory Generation
   ---------------------------------------------------------------------------

   function Generate_Trajectory (Initial   : State_Vector;
                                 T_Start   : Time_Seconds;
                                 T_End     : Time_Seconds;
                                 N_Points  : Positive;
                                 Model     : Force_Model'Class) return Trajectory is
      Result : Trajectory (1 .. N_Points);
      Dt : constant Time_Seconds := Time_Seconds (
         (Real (T_End) - Real (T_Start)) / Real (N_Points - 1));
      Current_State : State_Vector := Initial;
      T : Time_Seconds := T_Start;
      Step : constant Time_Seconds := Time_Seconds (abs (Real (Dt)) / 10.0);
         --  Use 10 substeps per output point

   begin
      Result (1) := Initial;

      for I in 2 .. N_Points loop
         declare
            T_Next : constant Time_Seconds := T_Start +
               Time_Seconds (Real (I - 1) * Real (Dt));
         begin
            Current_State := Propagate_RK4 (Current_State, T, T_Next, Step, Model);
            Result (I) := Current_State;
            T := T_Next;
         end;
      end loop;

      return Result;
   end Generate_Trajectory;

   function Generate_Timed_Trajectory (Initial   : State_Vector;
                                       T_Start   : Time_Seconds;
                                       T_End     : Time_Seconds;
                                       N_Points  : Positive;
                                       Model     : Force_Model'Class) return Timed_Trajectory is
      Result : Timed_Trajectory (1 .. N_Points);
      Traj : constant Trajectory := Generate_Trajectory (Initial, T_Start, T_End, N_Points, Model);
      Dt : constant Time_Seconds := Time_Seconds (
         (Real (T_End) - Real (T_Start)) / Real (N_Points - 1));

   begin
      for I in 1 .. N_Points loop
         Result (I).Time := T_Start + Time_Seconds (Real (I - 1) * Real (Dt));
         Result (I).State := Traj (I);
      end loop;

      return Result;
   end Generate_Timed_Trajectory;

   ---------------------------------------------------------------------------
   -- Utility Functions
   ---------------------------------------------------------------------------

   function Conserved_Energy (State : State_Vector;
                              Mu    : Gravitational_Parameter) return Specific_Energy is
      R_Mag : constant Real := Magnitude (State.Position);
      V_Mag : constant Real := Magnitude (State.Velocity);
   begin
      --  E = v^2/2 - mu/r
      return Specific_Energy ((V_Mag ** 2) / 2.0 - Real (Mu) / R_Mag);
   end Conserved_Energy;

   function Energy_Error (Initial : State_Vector;
                          Final   : State_Vector;
                          Mu      : Gravitational_Parameter) return Real is
      E_Initial : constant Specific_Energy := Conserved_Energy (Initial, Mu);
      E_Final : constant Specific_Energy := Conserved_Energy (Final, Mu);
   begin
      if abs (Real (E_Initial)) < 1.0e-20 then
         return abs (Real (E_Final));
      else
         return abs (Real (E_Final) - Real (E_Initial)) / abs (Real (E_Initial));
      end if;
   end Energy_Error;

   ---------------------------------------------------------------------------
   -- Parallel Propagation (static task pool)
   ---------------------------------------------------------------------------
   --  Ensemble propagation over a pool of worker tasks.  The index range is
   --  partitioned statically (near-equal contiguous slices), each worker
   --  propagates its slice independently, and any worker exception is
   --  captured and re-raised in the caller once every worker has completed,
   --  so the function never returns a partially initialized result.
   --  Workers perform no console I/O.  Because every sample is propagated
   --  independently by the same sequential algorithm, results are
   --  bit-identical to sequential propagation and deterministic across runs.

   Max_Parallel_Workers : constant := 8;

   generic
      with function Propagate_One (Sample : State_Vector) return State_Vector;
   procedure Pool_Propagate (Samples : State_Array;
                             Result  : out State_Array);
   --  Propagate Samples (I) into Result (I) for all I using a task pool

   procedure Pool_Propagate (Samples : State_Array;
                             Result  : out State_Array) is

      Worker_Count : constant Positive :=
         Positive'Max (1, Natural'Min (Samples'Length, Max_Parallel_Workers));

      --  Collects the first exception raised by any worker
      protected Failures is
         procedure Capture (X : Ada.Exceptions.Exception_Occurrence);
         function Failed return Boolean;
         procedure Extract (Into : out Ada.Exceptions.Exception_Occurrence);
      private
         Have  : Boolean := False;
         First : Ada.Exceptions.Exception_Occurrence;
      end Failures;

      protected body Failures is
         procedure Capture (X : Ada.Exceptions.Exception_Occurrence) is
         begin
            if not Have then
               Ada.Exceptions.Save_Occurrence (First, X);
               Have := True;
            end if;
         end Capture;

         function Failed return Boolean is (Have);

         procedure Extract (Into : out Ada.Exceptions.Exception_Occurrence) is
         begin
            Ada.Exceptions.Save_Occurrence (Into, First);
         end Extract;
      end Failures;

   begin
      if Samples'Length = 0 then
         return;
      end if;

      declare
         task type Worker is
            entry Assign (First_Index : Positive; Last_Index : Natural);
         end Worker;

         task body Worker is
            First : Positive := Positive'Last;
            Last  : Natural := 0;
         begin
            select
               accept Assign (First_Index : Positive; Last_Index : Natural) do
                  First := First_Index;
                  Last  := Last_Index;
               end Assign;
            or
               terminate;
            end select;

            for I in First .. Last loop
               Result (I) := Propagate_One (Samples (I));
            end loop;
         exception
            when X : others =>
               --  No console I/O in tasks: record and let the master re-raise
               Failures.Capture (X);
         end Worker;

         Workers : array (1 .. Worker_Count) of Worker;

         Next      : Positive := Samples'First;
         Remaining : Natural := Samples'Length;
      begin
         --  Static, deterministic partition into near-equal contiguous slices
         for W in Workers'Range loop
            declare
               Share : constant Natural := Remaining / (Worker_Count - W + 1);
            begin
               Workers (W).Assign (Next, Next + Share - 1);
               if Share > 0 then
                  Next := Next + Share;
                  Remaining := Remaining - Share;
               end if;
            end;
         end loop;
      end;
      --  All workers have terminated here (block exit awaits task completion)

      if Failures.Failed then
         declare
            X : Ada.Exceptions.Exception_Occurrence;
         begin
            Failures.Extract (X);
            Ada.Exceptions.Reraise_Occurrence (X);
         end;
      end if;
   end Pool_Propagate;

   function Propagate_Parallel (Samples   : State_Array;
                                T_Start   : Time_Seconds;
                                T_End     : Time_Seconds;
                                Tolerance : Real;
                                Model     : Two_Body_Model) return State_Array is

      function One (Sample : State_Vector) return State_Vector is
         (Propagate_RK78 (Sample, T_Start, T_End, Tolerance, Model));

      procedure Run_Pool is new Pool_Propagate (Propagate_One => One);

      Result : State_Array (Samples'Range);
   begin
      Run_Pool (Samples, Result);
      return Result;
   end Propagate_Parallel;

   function Propagate_Parallel_RK4 (Samples : State_Array;
                                    T_Start : Time_Seconds;
                                    T_End   : Time_Seconds;
                                    Step    : Time_Seconds;
                                    Model   : Two_Body_Model) return State_Array is

      function One (Sample : State_Vector) return State_Vector is
         (Propagate_RK4 (Sample, T_Start, T_End, Step, Model));

      procedure Run_Pool is new Pool_Propagate (Propagate_One => One);

      Result : State_Array (Samples'Range);
   begin
      Run_Pool (Samples, Result);
      return Result;
   end Propagate_Parallel_RK4;

   function Compute_Statistics (States : State_Array) return Statistics_Record is
      Result : Statistics_Record;
      N : constant Real := Real (States'Length);
      Sum_Pos : Vector_3D := (0.0, 0.0, 0.0);
      Sum_Vel : Vector_3D := (0.0, 0.0, 0.0);
      Sum_Sq_Pos : Real := 0.0;
      Sum_Sq_Vel : Real := 0.0;
      R : Real;
      Min_R : Real := Real'Last;
      Max_R : Real := Real'First;
   begin
      --  Compute sums for mean
      for S of States loop
         Sum_Pos := Sum_Pos + S.Position;
         Sum_Vel := Sum_Vel + S.Velocity;

         R := Magnitude (S.Position);
         Min_R := Real'Min (Min_R, R);
         Max_R := Real'Max (Max_R, R);
      end loop;

      --  Compute means
      Result.Mean_Position := (1.0 / N) * Sum_Pos;
      Result.Mean_Velocity := (1.0 / N) * Sum_Vel;
      Result.Min_Radius := Min_R;
      Result.Max_Radius := Max_R;

      --  Compute standard deviations
      for S of States loop
         declare
            Diff_Pos : constant Vector_3D := S.Position - Result.Mean_Position;
            Diff_Vel : constant Vector_3D := S.Velocity - Result.Mean_Velocity;
         begin
            Sum_Sq_Pos := Sum_Sq_Pos + Magnitude (Diff_Pos) ** 2;
            Sum_Sq_Vel := Sum_Sq_Vel + Magnitude (Diff_Vel) ** 2;
         end;
      end loop;

      if N > 1.0 then
         Result.Std_Dev_Position := Sqrt (Sum_Sq_Pos / (N - 1.0));
         Result.Std_Dev_Velocity := Sqrt (Sum_Sq_Vel / (N - 1.0));
      else
         Result.Std_Dev_Position := 0.0;
         Result.Std_Dev_Velocity := 0.0;
      end if;

      return Result;
   end Compute_Statistics;

end Hale_Orbital.Propagation;
