-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Numerical Propagation Package
-------------------------------------------------------------------------------
-- This package provides numerical integration methods for orbit propagation.
--
-- Implements:
--   - RK4 (4th order Runge-Kutta) fixed-step integrator
--   - DP54 (Dormand-Prince 5(4), DOPRI5) adaptive-step integrator
--   - RK78 (Fehlberg 7(8), NASA TR R-287) adaptive-step integrator
--   - Force model interface for extensible dynamics
--   - Trajectory generation utilities
--
-- References: Vallado, "Fundamentals of Astrodynamics and Applications"
--             Chapter 8: Numerical Integration
--             Dormand & Prince (1980), J. Comp. Appl. Math. 6(1), pp. 19-26
--             Fehlberg (1968), NASA TR R-287
-------------------------------------------------------------------------------

with Hale_Orbital.Types; use Hale_Orbital.Types;

package Hale_Orbital.Propagation is

   pragma Preelaborate;

   ---------------------------------------------------------------------------
   -- Force Model Interface
   ---------------------------------------------------------------------------
   --  Abstract interface for computing accelerations.
   --  Allows for different force models (two-body, J2, etc.)

   type Force_Model is interface;

   function Acceleration (Model : Force_Model;
                          T     : Time_Seconds;
                          State : State_Vector) return Vector_3D is abstract;
   --  Compute acceleration at given time and state

   ---------------------------------------------------------------------------
   -- Two-Body Force Model
   ---------------------------------------------------------------------------
   --  Simple Keplerian two-body dynamics: a = -mu * r / |r|^3

   type Two_Body_Model is new Force_Model with record
      Mu : Gravitational_Parameter;
   end record;

   overriding
   function Acceleration (Model : Two_Body_Model;
                          T     : Time_Seconds;
                          State : State_Vector) return Vector_3D;

   ---------------------------------------------------------------------------
   -- J2 Perturbation Model
   ---------------------------------------------------------------------------
   --  Two-body with J2 oblateness perturbation

   type J2_Model is new Force_Model with record
      Mu      : Gravitational_Parameter;
      J2      : Real;           -- J2 coefficient (dimensionless)
      R_Eq    : Distance_Km;    -- Equatorial radius
   end record;

   overriding
   function Acceleration (Model : J2_Model;
                          T     : Time_Seconds;
                          State : State_Vector) return Vector_3D;

   ---------------------------------------------------------------------------
   -- Propagator Configuration
   ---------------------------------------------------------------------------

   type Propagator_Config is record
      Step_Size     : Time_Seconds := 60.0;       -- Default 60s step
      Tolerance     : Real := 1.0e-12;            -- Adaptive step tolerance
      Min_Step      : Time_Seconds := 0.001;      -- Minimum step size
      Max_Step      : Time_Seconds := 86400.0;    -- Maximum step size (1 day)
      Max_Steps     : Positive := 1_000_000;      -- Maximum integration steps
   end record;

   Default_Config : constant Propagator_Config := (others => <>);

   ---------------------------------------------------------------------------
   -- Propagation Results
   ---------------------------------------------------------------------------

   type Propagation_Result is record
      Final_State : State_Vector;
      Steps_Used  : Natural;
      Success     : Boolean;
      Message     : String (1 .. 80);
   end record;

   ---------------------------------------------------------------------------
   -- Trajectory Array
   ---------------------------------------------------------------------------

   type Trajectory is array (Positive range <>) of State_Vector;

   type Trajectory_Point is record
      Time  : Time_Seconds;
      State : State_Vector;
   end record;

   type Timed_Trajectory is array (Positive range <>) of Trajectory_Point;

   ---------------------------------------------------------------------------
   -- RK4 Fixed-Step Propagator
   ---------------------------------------------------------------------------
   --  Classical 4th-order Runge-Kutta method
   --  Simple, robust, fixed step size

   function Propagate_RK4 (Initial  : State_Vector;
                           T_Start  : Time_Seconds;
                           T_End    : Time_Seconds;
                           Step     : Time_Seconds;
                           Model    : Force_Model'Class) return State_Vector;
   --  Propagate from T_Start to T_End using fixed step size
   --  Returns final state at T_End

   function Propagate_RK4 (Initial : State_Vector;
                           T_Start : Time_Seconds;
                           T_End   : Time_Seconds;
                           Config  : Propagator_Config;
                           Model   : Force_Model'Class) return Propagation_Result;
   --  Propagate with configuration, returns detailed result

   ---------------------------------------------------------------------------
   -- DP54 Adaptive-Step Propagator
   ---------------------------------------------------------------------------
   --  Dormand-Prince 5(4) embedded method (DOPRI5): 7 stages, 5th-order
   --  propagation with an embedded 4th-order solution for error estimation.
   --  Step size controller uses exponent 1/5 with a 0.9 safety factor.
   --  Reference: Dormand & Prince (1980)

   function Propagate_DP54 (Initial   : State_Vector;
                            T_Start   : Time_Seconds;
                            T_End     : Time_Seconds;
                            Tolerance : Real;
                            Model     : Force_Model'Class) return State_Vector;
   --  Propagate with adaptive step size based on local error tolerance
   --  Returns final state at T_End

   function Propagate_DP54 (Initial : State_Vector;
                            T_Start : Time_Seconds;
                            T_End   : Time_Seconds;
                            Config  : Propagator_Config;
                            Model   : Force_Model'Class) return Propagation_Result;
   --  Propagate with full configuration

   ---------------------------------------------------------------------------
   -- RK78 Adaptive-Step Propagator
   ---------------------------------------------------------------------------
   --  Fehlberg 7(8) embedded method (RKF78): 13 stages, 7th-order
   --  propagation with an embedded 8th-order solution for error estimation.
   --  Step size controller uses exponent 1/8 with a 0.9 safety factor.
   --  Reference: Fehlberg (1968), NASA TR R-287

   function Propagate_RK78 (Initial   : State_Vector;
                            T_Start   : Time_Seconds;
                            T_End     : Time_Seconds;
                            Tolerance : Real;
                            Model     : Force_Model'Class) return State_Vector;
   --  Propagate with adaptive step size based on local error tolerance
   --  Returns final state at T_End

   function Propagate_RK78 (Initial : State_Vector;
                            T_Start : Time_Seconds;
                            T_End   : Time_Seconds;
                            Config  : Propagator_Config;
                            Model   : Force_Model'Class) return Propagation_Result;
   --  Propagate with full configuration

   ---------------------------------------------------------------------------
   -- Trajectory Generation
   ---------------------------------------------------------------------------
   --  Generate trajectory with multiple output points

   function Generate_Trajectory (Initial   : State_Vector;
                                 T_Start   : Time_Seconds;
                                 T_End     : Time_Seconds;
                                 N_Points  : Positive;
                                 Model     : Force_Model'Class) return Trajectory;
   --  Generate trajectory with N_Points evenly spaced in time
   --  Uses RK4 internally for integration

   function Generate_Timed_Trajectory (Initial   : State_Vector;
                                       T_Start   : Time_Seconds;
                                       T_End     : Time_Seconds;
                                       N_Points  : Positive;
                                       Model     : Force_Model'Class) return Timed_Trajectory;
   --  Generate trajectory with timestamps

   ---------------------------------------------------------------------------
   -- Utility Functions
   ---------------------------------------------------------------------------

   function State_Derivative (State : State_Vector;
                              Accel : Vector_3D) return State_Vector;
   --  Compute state derivative: (v, a)
   --  Position derivative = velocity
   --  Velocity derivative = acceleration

   function Conserved_Energy (State : State_Vector;
                              Mu    : Gravitational_Parameter) return Specific_Energy;
   --  Compute specific orbital energy (should be conserved in two-body)
   --  E = v^2/2 - mu/r

   function Energy_Error (Initial : State_Vector;
                          Final   : State_Vector;
                          Mu      : Gravitational_Parameter) return Real;
   --  Compute relative energy error between two states

   ---------------------------------------------------------------------------
   -- Parallel Propagation
   ---------------------------------------------------------------------------
   --  Monte Carlo and ensemble propagation using a static Ada task pool
   --  Allows efficient parallel processing of multiple initial conditions

   type State_Array is array (Positive range <>) of State_Vector;

   type Parallel_Result is record
      Final_States   : access State_Array;
      Success_Count  : Natural;
      Total_Count    : Natural;
   end record;

   function Propagate_Parallel (Samples   : State_Array;
                                T_Start   : Time_Seconds;
                                T_End     : Time_Seconds;
                                Tolerance : Real;
                                Model     : Two_Body_Model) return State_Array;
   --  Propagate multiple initial states in parallel using a static task pool
   --  (worker count = min(Samples'Length, 8), static index partitioning)
   --  Each sample is propagated independently using the RK78 (Fehlberg 7(8))
   --  adaptive integrator; results are bit-identical to sequential calls
   --  If any worker raises, one captured exception is re-raised after all
   --  workers have completed (the function never returns partial results)
   --  Pre: Samples'Length > 0
   --  Post: Result'Length = Samples'Length

   function Propagate_Parallel_RK4 (Samples : State_Array;
                                    T_Start : Time_Seconds;
                                    T_End   : Time_Seconds;
                                    Step    : Time_Seconds;
                                    Model   : Two_Body_Model) return State_Array;
   --  Propagate multiple initial states in parallel using RK4 fixed-step
   --  Same task-pool scheme as Propagate_Parallel
   --  Simpler and faster for cases where adaptive step is not needed

   type Statistics_Record is record
      Mean_Position     : Vector_3D;
      Mean_Velocity     : Vector_3D;
      Std_Dev_Position  : Real;
      Std_Dev_Velocity  : Real;
      Min_Radius        : Real;
      Max_Radius        : Real;
   end record;

   function Compute_Statistics (States : State_Array) return Statistics_Record;
   --  Compute statistical summary of an ensemble of states
   --  Useful for Monte Carlo uncertainty quantification

end Hale_Orbital.Propagation;
