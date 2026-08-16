-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Three-Body Package (CR3BP)
-------------------------------------------------------------------------------
-- This package implements the Circular Restricted Three-Body Problem (CR3BP)
-- for analyzing spacecraft trajectories in systems like Earth-Moon or Sun-Earth.
--
-- The CR3BP assumes:
--   1. Two primary bodies (P1, P2) orbit their barycenter in circular orbits
--   2. Third body (spacecraft) has negligible mass
--   3. Motion is studied in a rotating reference frame
--
-- Reference: Hale Chapter 10, Szebehely "Theory of Orbits"
-------------------------------------------------------------------------------

with Hale_Orbital.Types;  use Hale_Orbital.Types;

package Hale_Orbital.Threebody
   with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Three-Body System Definition
   ---------------------------------------------------------------------------

   --  Represents a three-body system (e.g., Earth-Moon, Sun-Earth)
   type Threebody_System is record
      Name           : String (1 .. 20);
      Mu1            : Gravitational_Parameter;  -- Primary body (larger)
      Mu2            : Gravitational_Parameter;  -- Secondary body (smaller)
      Distance       : Distance_Km;              -- Separation between primaries
      Mass_Ratio     : Real;                     -- mu = M2/(M1+M2), dimensionless
   end record;

   --  Normalized state in rotating frame
   type Normalized_State is record
      X  : Real;  -- Normalized x position (along P1-P2 line)
      Y  : Real;  -- Normalized y position (perpendicular in plane)
      Z  : Real;  -- Normalized z position (out of plane)
      VX : Real;  -- Normalized x velocity
      VY : Real;  -- Normalized y velocity
      VZ : Real;  -- Normalized z velocity
   end record;

   ---------------------------------------------------------------------------
   -- Predefined Three-Body Systems
   ---------------------------------------------------------------------------

   Earth_Moon_System : constant Threebody_System;
   Sun_Earth_System  : constant Threebody_System;
   Sun_Jupiter_System : constant Threebody_System;

   ---------------------------------------------------------------------------
   -- Lagrange Points
   ---------------------------------------------------------------------------

   type Lagrange_Point is (L1, L2, L3, L4, L5);

   type Lagrange_Result is record
      Point     : Lagrange_Point;
      X         : Real;  -- Normalized x coordinate
      Y         : Real;  -- Normalized y coordinate
      Distance  : Distance_Km;  -- Physical distance from primary
      Converged : Boolean;  -- True if the Newton iteration for the collinear
                            -- points met its tolerance (always True for the
                            -- analytic L4/L5 points)
   end record;

   --  Compute location of a Lagrange point
   function Compute_Lagrange_Point
      (System : Threebody_System;
       Point  : Lagrange_Point) return Lagrange_Result
   with
      Pre => System.Mass_Ratio > 0.0 and System.Mass_Ratio < 0.5,
      Global => null;

   --  Compute all five Lagrange points
   type Lagrange_Array is array (Lagrange_Point) of Lagrange_Result;
   function Compute_All_Lagrange_Points
      (System : Threebody_System) return Lagrange_Array
   with
      Pre => System.Mass_Ratio > 0.0 and System.Mass_Ratio < 0.5,
      Global => null;

   ---------------------------------------------------------------------------
   -- CR3BP Equations of Motion
   ---------------------------------------------------------------------------

   --  Compute the pseudo-potential (Jacobi integral component)
   function Pseudo_Potential
      (X, Y, Z : Real;
       Mu      : Real) return Real
   with
      Pre => Mu > 0.0 and Mu < 1.0,
      Global => null;

   --  Compute acceleration in the rotating frame
   procedure Compute_Acceleration
      (State : in  Normalized_State;
       Mu    : in  Real;
       AX    : out Real;
       AY    : out Real;
       AZ    : out Real)
   with
      Pre => Mu > 0.0 and Mu < 1.0,
      Global => null,
      Depends => ((AX, AY, AZ) => (State, Mu));

   --  Compute Jacobi constant (energy integral)
   function Jacobi_Constant
      (State : Normalized_State;
       Mu    : Real) return Real
   with
      Pre => Mu > 0.0 and Mu < 1.0,
      Global => null;

   ---------------------------------------------------------------------------
   -- State Propagation
   ---------------------------------------------------------------------------

   type Integration_Method is (Euler, RK4, RK45);

   --  Propagate state forward in normalized time.
   --
   --  Euler and RK4 are fixed-step methods: the trajectory is advanced with
   --  constant step Step_Size (the last step is shortened to land exactly on
   --  T_Final).
   --
   --  RK45 is the adaptive embedded Runge-Kutta-Fehlberg 4(5) method (same
   --  Butcher tableau and step-size controller convention as the Python
   --  oracle in python/three-body-extension/src/threebody/integrators.py):
   --  the solution is advanced with the 5th-order result (local
   --  extrapolation), the local error is estimated from the difference of
   --  the embedded 4th- and 5th-order solutions, and the step is accepted
   --  when that error is below an internal tolerance (1.0e-10).  The next
   --  step is scaled by 0.9 * (tol/error)**(1/5), limited to [H/10, 5*H].
   --  For RK45 the Step_Size parameter is the INITIAL and MAXIMUM step size;
   --  the adaptive step is carried forward between iterations and clamped so
   --  the propagation ends exactly at T_Final.
   function Propagate
      (Initial_State : Normalized_State;
       Mu            : Real;
       T_Final       : Real;
       Step_Size     : Real := 0.001;
       Method        : Integration_Method := RK4) return Normalized_State
   with
      Pre => Mu > 0.0 and Mu < 1.0 and Step_Size > 0.0,
      Global => null;

   ---------------------------------------------------------------------------
   -- Stability Analysis
   ---------------------------------------------------------------------------

   type Stability_Result is record
      Is_Stable       : Boolean;
      Eigenvalue_Real : Real;
      Eigenvalue_Imag : Real;
      Period          : Real;  -- If periodic, the period in normalized time
   end record;

   --  Analyze stability at a Lagrange point
   function Analyze_Stability
      (System : Threebody_System;
       Point  : Lagrange_Point) return Stability_Result
   with
      Pre => System.Mass_Ratio > 0.0 and System.Mass_Ratio < 0.5,
      Global => null;

   ---------------------------------------------------------------------------
   -- Coordinate Conversions
   ---------------------------------------------------------------------------

   --  Convert dimensional state to normalized
   function To_Normalized
      (Position : Position_Vector;
       Velocity : Velocity_Vector;
       System   : Threebody_System) return Normalized_State
   with
      Pre => System.Distance > Distance_Km (0.0),
      Global => null;

   --  Convert normalized state to dimensional
   procedure To_Dimensional
      (State    : in  Normalized_State;
       System   : in  Threebody_System;
       Position : out Position_Vector;
       Velocity : out Velocity_Vector)
   with
      Pre => System.Distance > Distance_Km (0.0),
      Global => null,
      Depends => ((Position, Velocity) => (State, System));

   --  Convert normalized time to seconds
   function Normalized_Time_To_Seconds
      (T_Norm : Real;
       System : Threebody_System) return Time_Seconds
   with
      Pre => Real (System.Distance) > 0.0,
      Global => null;

   ---------------------------------------------------------------------------
   -- State Transition Matrix (STM) for Variational Equations
   ---------------------------------------------------------------------------
   --  The STM tracks how small perturbations to initial conditions evolve.
   --  Essential for differential correction and stability analysis.

   --  The 6x6 STM/monodromy matrices use Hale_Orbital.Types.Matrix_6x6
   --  directly (visible through the "use Hale_Orbital.Types" clause above).
   --  A local re-declaration used to shadow it, making the two types
   --  incompatible and the unqualified name ambiguous for clients that
   --  "use" both packages; it was removed.

   --  Identity matrix for STM initialization
   Identity_6x6 : constant Matrix_6x6;

   --  State with attached State Transition Matrix
   type State_With_STM is record
      State : Normalized_State;
      STM   : Matrix_6x6;
   end record;

   --  Propagate state along with the State Transition Matrix
   function Propagate_With_STM
      (Initial_State : Normalized_State;
       Mu            : Real;
       T_Final       : Real;
       Step_Size     : Real := 0.001) return State_With_STM
   with
      Pre => Mu > 0.0 and Mu < 1.0 and Step_Size > 0.0,
      Global => null;

   ---------------------------------------------------------------------------
   -- Monodromy Matrix and Floquet Analysis
   ---------------------------------------------------------------------------
   --  The monodromy matrix is the STM after one complete orbital period.
   --  Its eigenvalues (Floquet multipliers) determine orbital stability.

   type Complex_Number is record
      Re : Real;
      Im : Real;
   end record;

   type Complex_Vector_6 is array (1 .. 6) of Complex_Number;

   type Floquet_Result is record
      Monodromy       : Matrix_6x6;
      Multipliers     : Complex_Vector_6;
      --  All six Floquet multipliers, stored as reciprocal pairs:
      --  (1,2), (3,4) and (5,6) each satisfy lambda_i * lambda_j = 1, and
      --  the pairs are ordered by descending magnitude of their dominant
      --  member, so the dominant pair occupies slots 1-2.
      Max_Multiplier  : Real;     -- Max |eigenvalue|
      Is_Stable       : Boolean;  -- True if all |eigenvalues| <= 1 + tol
      Stability_Index : Real;
      --  Standard stability index convention:
      --  nu = (lambda_max + 1/lambda_max)/2 = sigma_max/2
      Valid           : Boolean;
      --  True only when the input passed both sanity residual checks:
      --  (1) it is symplectic: the normalized Frobenius norm of
      --      Mp'*J*Mp - J is small, where J is the standard symplectic
      --      form and Mp is the monodromy transformed to canonical
      --      coordinates (px = vx - y, py = vy + x, pz = vz), since the
      --      CR3BP flow is Hamiltonian in momenta, not velocities; and
      --  (2) it carries the trivial multiplier pair of a periodic-orbit
      --      monodromy (an eigenvalue pair at 1, i.e. one sigma ~ 2).
      --      This threshold is conditioning-aware: the reduced-cubic
      --      coefficients are formed from tr(M^k), whose rounding error
      --      grows like Eps * tr(M)**2, so the sigma ~ 2 residual of an
      --      exactly symplectic monodromy grows the same way and a fixed
      --      tolerance would wrongly reject strongly unstable orbits.
      --  When Valid is False the multipliers are still reported but should
      --  not be trusted as Floquet multipliers of a periodic orbit.
      Condition_Warning : Boolean;
      --  True when Eps * (1 + tr(M)**2) > 1.0e-8 (Eps = Real'Model_Epsilon),
      --  i.e. rounding in the reduced-cubic coefficients can move the
      --  center/trivial sigma roots by more than ~1e-8; since the defective
      --  trivial pair amplifies sigma error by a square root
      --  (|lambda - 1| ~ sqrt (|sigma - 2|)), those multipliers may then
      --  carry more than ~1e-4 error even though Valid is True.  Beyond
      --  |tr M| ~ 3e4 the reduced-cubic multipliers degrade and only the
      --  dominant pair remains reliable.
   end record;

   --  Compute monodromy matrix for a periodic orbit
   function Compute_Monodromy
      (Initial_State : Normalized_State;
       Mu            : Real;
       Period        : Real;
       Step_Size     : Real := 0.0001) return Matrix_6x6
   with
      Pre => Mu > 0.0 and Mu < 1.0 and Period > 0.0 and Step_Size > 0.0,
      Global => null;

   --  Compute Floquet multipliers from monodromy matrix.
   --
   --  CONTRACT: the input is assumed to be the monodromy matrix of a CR3BP
   --  periodic orbit, i.e. a symplectic matrix.  The eigenvalues of such a
   --  matrix come in reciprocal pairs, so its characteristic polynomial is
   --  palindromic and, with sigma = lambda + 1/lambda, reduces to a cubic
   --  that is solved in closed form (no general QR iteration is performed).
   --  The Valid flag of the result reports whether the input actually
   --  satisfied the symplectic and trivial-pair residual checks; for a
   --  non-symplectic input the returned multipliers are meaningless.
   --
   --  Measured validity envelope (exactly symplectic synthetic monodromies,
   --  64-bit IEEE Real; see hale_tests-periodic_orbits.adb): the reduced
   --  cubic's coefficients are formed from tr(M^k), so their absolute
   --  rounding error grows like Eps * lambda_max**2 and the accuracy of the
   --  small-sigma roots degrades with the dominant multiplier:
   --    * dominant pair: accurate to ~1e-9 relative (observed ~1e-15) up
   --      to at least lambda_max = 1e6;
   --    * center (unit-circle) pair: absolute error grows with
   --      lambda_max**2 - observed ~3e-8 at lambda_max = 3e4, ~7e-6 at
   --      1e5, ~1.5e-4 at 1e6;
   --    * trivial pair: |lambda - 1| ~ sqrt (|sigma - 2| residual), the
   --      square-root amplification of a defective (Jordan) pair -
   --      observed ~2.4e-4 at lambda_max = 3e4, ~2.3e-3 at 1e5, ~1e-2 at
   --      1e6.  Beyond |tr M| ~ 3e4 the reduced-cubic multipliers degrade
   --      past 1e-4 and only the dominant pair remains fully reliable.
   --  The trivial-pair validity threshold scales with Eps * (1 + tr(M)**2)
   --  accordingly, and Condition_Warning flags results whose center/trivial
   --  multipliers may carry more than ~1e-4 error despite Valid = True.
   function Analyze_Floquet (Monodromy : Matrix_6x6) return Floquet_Result
      with Global => null;

   ---------------------------------------------------------------------------
   -- Periodic Orbit Computation
   ---------------------------------------------------------------------------
   --  Differential correction to find periodic orbits around Lagrange points.
   --  Supports both planar (Lyapunov) and 3D (Halo) orbits.

   type Periodic_Orbit_Type is (Lyapunov, Halo_Northern, Halo_Southern);

   type Periodic_Orbit is record
      Orbit_Type      : Periodic_Orbit_Type;
      Initial_State   : Normalized_State;
      Period          : Real;              -- Normalized period
      Jacobi          : Real;              -- Jacobi constant
      Amplitude_X     : Real;              -- X amplitude from Lagrange point
      Amplitude_Z     : Real;              -- Z amplitude (0 for Lyapunov)
      Converged       : Boolean;
      Iterations_Used : Natural;
   end record;

   --  Find a Lyapunov orbit (planar periodic orbit around L1, L2, or L3)
   function Find_Lyapunov_Orbit
      (System          : Threebody_System;
       Point           : Lagrange_Point;
       Amplitude       : Real;          -- Desired x-amplitude
       Initial_Guess_Y : Real := 0.0;   -- Optional initial y-velocity
       Tolerance       : Real := 1.0e-10;
       Max_Iterations  : Positive := 50) return Periodic_Orbit
   with
      Pre => System.Mass_Ratio > 0.0 and System.Mass_Ratio < 0.5
             and Amplitude > 0.0
             and Point in L1 | L2 | L3,
      Global => null;

   --  Find a Halo orbit (3D periodic orbit around L1 or L2)
   function Find_Halo_Orbit
      (System         : Threebody_System;
       Point          : Lagrange_Point;
       Amplitude_Z    : Real;           -- Desired z-amplitude
       Family         : Periodic_Orbit_Type := Halo_Northern;
       Tolerance      : Real := 1.0e-10;
       Max_Iterations : Positive := 50) return Periodic_Orbit
   with
      Pre => System.Mass_Ratio > 0.0 and System.Mass_Ratio < 0.5
             and Amplitude_Z > 0.0
             and Point in L1 | L2
             and Family in Halo_Northern | Halo_Southern,
      Global => null;

   --  Richardson third-order approximation for Halo orbit initial guess
   function Richardson_Halo_Guess
      (System      : Threebody_System;
       Point       : Lagrange_Point;
       Amplitude_Z : Real;
       Family      : Periodic_Orbit_Type := Halo_Northern) return Normalized_State
   with
      Pre => System.Mass_Ratio > 0.0 and System.Mass_Ratio < 0.5
             and Amplitude_Z > 0.0
             and Point in L1 | L2
             and Family in Halo_Northern | Halo_Southern,
      Global => null;

   --  Generate family of periodic orbits by continuation
   type Periodic_Orbit_Array is array (Positive range <>) of Periodic_Orbit;

   function Generate_Orbit_Family
      (System        : Threebody_System;
       Point         : Lagrange_Point;
       Orbit_Type    : Periodic_Orbit_Type;
       Amp_Start     : Real;
       Amp_End       : Real;
       Num_Orbits    : Positive;
       Tolerance     : Real := 1.0e-10) return Periodic_Orbit_Array
   with
      Pre => System.Mass_Ratio > 0.0 and System.Mass_Ratio < 0.5
             and Amp_Start > 0.0 and Amp_End > Amp_Start
             and Num_Orbits >= 2,
      Global => null;

   ---------------------------------------------------------------------------
   -- Ghost Functions for SPARK Proofs (ISS-019)
   ---------------------------------------------------------------------------
   --  These Ghost functions express mathematical invariants for CR3BP that
   --  can be verified by the SPARK prover.

   --  Ghost predicate: Jacobi constant is conserved during propagation
   --  Mathematical property: C_J(t) = C_J(0) for all t (energy integral)
   --  This is the fundamental invariant of the CR3BP
   function Jacobi_Is_Conserved (Initial : Normalized_State;
                                  Final   : Normalized_State;
                                  Mu      : Real;
                                  Tolerance : Real := 1.0e-10) return Boolean is
      (abs (Jacobi_Constant (Initial, Mu) - Jacobi_Constant (Final, Mu)) < Tolerance)
   with Ghost,
        Pre => Mu > 0.0 and Mu < 1.0;

   --  Ghost predicate: State is within valid bounds
   --  Mathematical property: Position cannot be at singularities (primaries)
   function Is_Valid_State (State : Normalized_State;
                            Mu    : Real) return Boolean is
      (declare
         R1_Sq : constant Real := (State.X + Mu) ** 2 + State.Y ** 2 + State.Z ** 2;
         R2_Sq : constant Real := (State.X - 1.0 + Mu) ** 2 + State.Y ** 2 + State.Z ** 2;
       begin
         R1_Sq > 1.0e-10 and R2_Sq > 1.0e-10)
   with Ghost,
        Pre => Mu > 0.0 and Mu < 1.0;

   --  Ghost predicate: Zero-velocity surface constraint
   --  Mathematical property: C_J >= 2*Omega for valid motion
   function Is_Above_Zero_Velocity_Surface (State : Normalized_State;
                                             Mu    : Real) return Boolean is
      (Jacobi_Constant (State, Mu) >= 2.0 * Pseudo_Potential (State.X, State.Y, State.Z, Mu))
   with Ghost,
        Pre => Mu > 0.0 and Mu < 1.0;

private

   --  Initialize system constants
   Earth_Moon_System : constant Threebody_System :=
      (Name       => "Earth-Moon          ",
       Mu1        => 398600.4418,         -- Earth GM (km^3/s^2)
       Mu2        => 4902.8,              -- Moon GM
       Distance   => 384400.0,            -- Earth-Moon distance (km)
       Mass_Ratio => 0.012150583916325);  -- Moon/(Earth+Moon) = Mu2/(Mu1+Mu2)

   Sun_Earth_System : constant Threebody_System :=
      (Name       => "Sun-Earth           ",
       Mu1        => 132712440018.0,      -- Sun GM
       Mu2        => 398600.4418,         -- Earth GM
       Distance   => 149597870.7,         -- 1 AU in km
       Mass_Ratio => 3.0034806424871E-6); -- Earth/(Sun+Earth) = Mu2/(Mu1+Mu2)

   Sun_Jupiter_System : constant Threebody_System :=
      (Name       => "Sun-Jupiter         ",
       Mu1        => 132712440018.0,      -- Sun GM
       Mu2        => 126686534.0,         -- Jupiter GM
       Distance   => 778570000.0,         -- Jupiter semi-major axis (km)
       Mass_Ratio => 9.5368388281602E-4); -- Jupiter/(Sun+Jupiter) = Mu2/(Mu1+Mu2)

   --  6x6 Identity matrix for STM initialization
   Identity_6x6 : constant Matrix_6x6 :=
      ((1.0, 0.0, 0.0, 0.0, 0.0, 0.0),
       (0.0, 1.0, 0.0, 0.0, 0.0, 0.0),
       (0.0, 0.0, 1.0, 0.0, 0.0, 0.0),
       (0.0, 0.0, 0.0, 1.0, 0.0, 0.0),
       (0.0, 0.0, 0.0, 0.0, 1.0, 0.0),
       (0.0, 0.0, 0.0, 0.0, 0.0, 1.0));

end Hale_Orbital.Threebody;
