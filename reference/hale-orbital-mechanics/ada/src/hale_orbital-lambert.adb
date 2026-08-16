-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Lambert Problem Solver Body
-------------------------------------------------------------------------------
-- Standard universal-variable formulation (Bate-Mueller-White; Vallado 4th
-- ed. Algorithm 59):
--    A      = Dm * sqrt(r1 * r2 * (1 + cos dnu))
--    y(z)   = r1 + r2 + A * (z*S(z) - 1) / sqrt(C(z))
--    chi    = sqrt(y / C(z))
--    sqrt(mu) * TOF = chi**3 * S(z) + A * sqrt(y)
--    f = 1 - y/r1,  g = A * sqrt(y/mu),  gdot = 1 - y/r2
--    v1 = (r2 - f*r1) / g,  v2 = (gdot*r2 - r1) / g
--
-- Robustness (ISS-010): every float division and square-root argument in the
-- solver core is explicitly guarded using Small_Threshold (DEC-009); no build
-- mode traps float division, so a guard violation reports Converged = False
-- instead of producing NaN/Inf velocities.  A converged result additionally
-- passes a finiteness gate ('Valid on every velocity component) and a
-- positive semi-major axis check, matching the Post contract on
-- Solve_Lambert: the single-revolution solver serves elliptic transfers, and
-- below the parabolic TOF limit (hyperbolic regime, a < 0) it reports
-- Converged = False rather than raising.
--
-- Multi-revolution enumeration: the N-rev elliptic solutions live in the
-- band z in (4*pi**2*N**2, 4*pi**2*(N+1)**2) (z = dE**2 with the total
-- eccentric-anomaly sweep dE in (2*pi*N, 2*pi*(N+1))).  TOF(z) is U-shaped
-- over each band, so a requested TOF admits 0 or 2 roots per band; the
-- interior minimum is located by golden-section search and each monotone
-- branch is bisected with the matching predicate direction (see
-- Locate_Band_Minimum and Solve_Lambert_Core.Increasing below).
-------------------------------------------------------------------------------

with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;   use Hale_Orbital.Vectors;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;
with Hale_Orbital.Elements;  use Hale_Orbital.Elements;
with Hale_Orbital.Kepler;    use Hale_Orbital.Kepler;
with Hale_Orbital.Stumpff;   use Hale_Orbital.Stumpff;

package body Hale_Orbital.Lambert
   with SPARK_Mode => Off  --  Body uses generic instantiation
is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   ---------------------------------------------------------------------------
   -- Shared Solver Core (ISS-010 deduplication)
   ---------------------------------------------------------------------------
   --  Solve_Lambert and Solve_Lambert_Bounded previously duplicated ~90% of
   --  their code with divergent Y < 0 recovery rules.  The single core below
   --  is parameterized by the Z bracket, the initial Z guess, and the
   --  recovery policy.  Both historical policies are preserved because they
   --  differ for a reason:
   --    * Rescale_Toward_Parabolic - pull Z toward 0 (parabolic); used by
   --      the public single-revolution solver.
   --    * Shrink_Bracket - confine bisection to the supplied bracket; used
   --      for multi-revolution Z windows, which must not escape their band.

   type Y_Recovery_Policy is (Rescale_Toward_Parabolic, Shrink_Bracket);

   --  Compute the Lambert y value at Z (standard universal-variable form):
   --     y(z) = r1 + r2 + A * (z*S(z) - 1) / sqrt(C(z))
   --  guarding the C(Z) denominator (DEC-009: guards use Small_Threshold
   --  because no build mode traps float division).  Ok = False marks a Z at
   --  which y is not computable; callers must treat the attempt as
   --  non-convergent.
   procedure Compute_Y (Z       : Real;
                        R_Sum   : Real;
                        A_Param : Real;
                        C_Z     : out Real;
                        S_Z     : out Real;
                        Y       : out Real;
                        Ok      : out Boolean) is
   begin
      C_Z := Stumpff.C (Z);
      S_Z := Stumpff.S (Z);
      Y := 0.0;
      Ok := False;

      --  Stumpff.C clamps to >= 0 and is exactly 0 at Z = (2k*pi)**2, so
      --  the division below must be guarded (ISS-010)
      if C_Z < Small_Threshold then
         return;
      end if;

      Y := R_Sum + A_Param * (Z * S_Z - 1.0) / Sqrt (C_Z);
      Ok := True;
   end Compute_Y;

   --  Transfer geometry shared by the solver core and the multi-revolution
   --  enumeration: R_Sum = r1 + r2 and the universal-variable parameter
   --  A = Dm * sqrt(r1 * r2 * (1 + cos dnu)), with the direction modifier
   --  Dm derived from the cross-product z-component and Long_Way.
   procedure Compute_Transfer_Geometry (R1       : Position_Vector;
                                        R2       : Position_Vector;
                                        Long_Way : Boolean;
                                        R_Sum    : out Real;
                                        A_Param  : out Real) is
      R1_Mag  : constant Real := Magnitude (R1);
      R2_Mag  : constant Real := Magnitude (R2);
      Cos_Dnu : Real;
      Dm      : Real;
   begin
      --  Transfer angle cosine, clamped for numerical safety
      --  (R1_Mag, R2_Mag > 0 is guaranteed by the callers' preconditions)
      Cos_Dnu := Dot (R1, R2) / (R1_Mag * R2_Mag);
      Cos_Dnu := Real'Max (-1.0, Real'Min (1.0, Cos_Dnu));

      --  Direction modifier based on cross product z-component
      declare
         Cross_Z : constant Real := Cross (R1, R2) (3);
      begin
         if Long_Way then
            Dm := (if Cross_Z >= 0.0 then -1.0 else 1.0);
         else
            Dm := (if Cross_Z >= 0.0 then 1.0 else -1.0);
         end if;
      end;

      R_Sum := R1_Mag + R2_Mag;
      A_Param := Dm * Sqrt (R1_Mag * R2_Mag * (1.0 + Cos_Dnu));
   end Compute_Transfer_Geometry;

   --  Time of flight at a given Z for a fixed transfer geometry (standard
   --  universal-variable form):
   --     chi = sqrt(y/C(z)),  sqrt(mu)*TOF = chi**3*S(z) + A*sqrt(y)
   --  Ok = False when y is not computable at Z (C(Z) ~ 0, near a
   --  multi-revolution band edge) or y < 0 (possible only from rounding
   --  in near-degenerate geometry for Z > 0).
   procedure Tof_At_Z (Z       : Real;
                       R_Sum   : Real;
                       A_Param : Real;
                       Sqrt_Mu : Real;
                       Tof_Z   : out Real;
                       Ok      : out Boolean) is
      C_Z, S_Z, Y : Real;
      Y_Ok        : Boolean;
   begin
      Tof_Z := 0.0;
      Ok := False;

      Compute_Y (Z, R_Sum, A_Param, C_Z, S_Z, Y, Y_Ok);
      if not Y_Ok or else Y < 0.0 then
         return;
      end if;

      declare
         Chi : constant Real := Sqrt (Y / C_Z);
      begin
         Tof_Z := (Chi**3 * S_Z + A_Param * Sqrt (Y)) / Sqrt_Mu;
      end;
      Ok := True;
   end Tof_At_Z;

   ---------------------------------------------------------------------------
   -- Multi-Revolution Band Enumeration (shared machinery)
   ---------------------------------------------------------------------------
   --  The N-revolution elliptic solutions live at z = dE**2 with the total
   --  eccentric-anomaly sweep dE in (2*pi*N, 2*pi*(N+1)), i.e. z in the band
   --     (4*pi**2*N**2, 4*pi**2*(N+1)**2).
   --  Over each band TOF(z) tends to +infinity at BOTH edges (the Stumpff
   --  C(z) vanishes there) and has exactly one interior minimum, so a
   --  requested TOF admits 0 or 2 roots per band, one on each monotone
   --  branch around the minimum.  Plain increasing-TOF bisection is only
   --  correct on the right (increasing) branch; the left branch needs the
   --  reversed predicate (see Solve_Lambert_Core.Increasing).

   Band_Edge_Margin : constant Real := 0.1;
   --  Offset kept off the exact band edges, where C(z) -> 0 defeats the
   --  guarded y evaluation (Compute_Y).  TOF at the margin scales like
   --  margin**(-3) (order 1e11 s and up for LEO-scale geometry), so no
   --  realistic requested TOF has its roots between edge and margin.

   Inv_Golden_Ratio : constant Real := 0.61803398874989485;  -- (sqrt(5)-1)/2

   --  Locate the interior TOF minimum of the N-rev band by golden-section
   --  search (TOF is strictly unimodal over the band).  On return
   --  [Z_Lo, Z_Min] is the decreasing branch and [Z_Min, Z_Hi] the
   --  increasing one.  Ok = False only if the minimum abscissa itself is
   --  not computable, which cannot happen for non-degenerate geometry.
   procedure Locate_Band_Minimum (N       : Positive;
                                  R_Sum   : Real;
                                  A_Param : Real;
                                  Sqrt_Mu : Real;
                                  Z_Lo    : out Real;
                                  Z_Hi    : out Real;
                                  Z_Min   : out Real;
                                  Tof_Min : out Real;
                                  Ok      : out Boolean) is
      Band_Lo : constant Real := 4.0 * Pi * Pi * Real (N) ** 2;
      Band_Hi : constant Real := 4.0 * Pi * Pi * Real (N + 1) ** 2;

      --  0.618**k interval reduction: 90 iterations reach double-precision
      --  resolution of the band long before the bound (bounded iteration
      --  per ISS-062 conventions)
      Max_Iter : constant := 90;

      A_Z, B_Z, C_Z, D_Z, F_C, F_D : Real;

      --  TOF at Z, or Real'Last where not computable: the minimizer then
      --  simply avoids that abscissa
      function Tof_Or_Huge (Z : Real) return Real is
         T_Val : Real;
         T_Ok  : Boolean;
      begin
         Tof_At_Z (Z, R_Sum, A_Param, Sqrt_Mu, T_Val, T_Ok);
         return (if T_Ok then T_Val else Real'Last);
      end Tof_Or_Huge;

   begin
      Z_Lo := Band_Lo + Band_Edge_Margin;
      Z_Hi := Band_Hi - Band_Edge_Margin;

      A_Z := Z_Lo;
      B_Z := Z_Hi;
      C_Z := B_Z - Inv_Golden_Ratio * (B_Z - A_Z);
      D_Z := A_Z + Inv_Golden_Ratio * (B_Z - A_Z);
      F_C := Tof_Or_Huge (C_Z);
      F_D := Tof_Or_Huge (D_Z);

      for Iter in 1 .. Max_Iter loop
         if F_C <= F_D then
            B_Z := D_Z;
            D_Z := C_Z;
            F_D := F_C;
            C_Z := B_Z - Inv_Golden_Ratio * (B_Z - A_Z);
            F_C := Tof_Or_Huge (C_Z);
         else
            A_Z := C_Z;
            C_Z := D_Z;
            F_C := F_D;
            D_Z := A_Z + Inv_Golden_Ratio * (B_Z - A_Z);
            F_D := Tof_Or_Huge (D_Z);
         end if;
         exit when B_Z - A_Z <= 1.0e-10 * (Band_Hi - Band_Lo);
      end loop;

      Z_Min := (A_Z + B_Z) / 2.0;

      declare
         T_Ok : Boolean;
      begin
         Tof_At_Z (Z_Min, R_Sum, A_Param, Sqrt_Mu, Tof_Min, T_Ok);
         Ok := T_Ok and then Tof_Min > 0.0;
      end;
   end Locate_Band_Minimum;

   --  Core bisection solver shared by Solve_Lambert (full single-revolution
   --  bracket, parabolic initial guess, rescale recovery) and
   --  Solve_Lambert_Bounded (caller-supplied bracket, midpoint initial
   --  guess, bracket-shrink recovery).  Increasing selects the bisection
   --  predicate direction: True when TOF grows with Z over the bracket
   --  (single-revolution bracket, right branch of a multi-rev band), False
   --  on the decreasing left branch of a multi-rev band.
   function Solve_Lambert_Core (R1          : Position_Vector;
                                R2          : Position_Vector;
                                Tof         : Time_Seconds;
                                Mu          : Gravitational_Parameter;
                                Long_Way    : Boolean;
                                Z_Low_Init  : Real;
                                Z_High_Init : Real;
                                Z_Init      : Real;
                                Policy      : Y_Recovery_Policy;
                                Increasing  : Boolean;
                                Tolerance   : Real) return Lambert_Result is
      --  Initialized so that non-converged returns never expose
      --  uninitialized (potentially invalid) components
      Result : Lambert_Result :=
         (V1         => (others => 0.0),
          V2         => (others => 0.0),
          A          => 0.0,
          E          => 0.0,
          Iterations => 0,
          Converged  => False);

      R1_Mag  : constant Real := Magnitude (R1);
      R2_Mag  : constant Real := Magnitude (R2);
      Mu_Val  : constant Real := Real (Mu);
      Sqrt_Mu : constant Real := Sqrt (Mu_Val);
      T       : constant Real := Real (Tof);

      R_Sum   : Real;
      A_Param : Real;
      Z, Z_Low, Z_High : Real;
      F_Z, C_Z, S_Z, Y : Real;
      A, F_Func, G_Func, G_Dot : Real;
      Y_Ok : Boolean;
      Iter : Natural := 0;
      Max_Iter : constant := 100;

   begin
      --  Transfer geometry: A = Dm * sqrt(r1 * r2 * (1 + cos dnu)).
      --  A = 0 is the 180-degree singularity (Solve_Lambert rejects it at
      --  entry; Solve_Lambert_Multi pre-guards it) - guarded here as well
      --  for the bounded path (ISS-010)
      Compute_Transfer_Geometry (R1, R2, Long_Way, R_Sum, A_Param);

      if abs (A_Param) < Small_Threshold then
         Result.Iterations := Iter;
         return Result;
      end if;

      Z_Low := Z_Low_Init;
      Z_High := Z_High_Init;
      Z := Z_Init;

      --  Bisection with bounded iteration count (ISS-062)
      loop
         pragma Loop_Invariant (Iter < Max_Iter);
         --  Invariant: iteration count bounded, bisection converges

         Compute_Y (Z, R_Sum, A_Param, C_Z, S_Z, Y, Y_Ok);

         if not Y_Ok then
            --  Guarded denominator violated (C(Z) ~ 0): report
            --  non-convergence instead of raising (ISS-010 policy)
            Result.Iterations := Iter;
            return Result;
         end if;

         if Y < 0.0 then
            --  Invalid Y: apply this solver's recovery policy
            case Policy is
               when Rescale_Toward_Parabolic =>
                  if Z > 0.0 then
                     Z := Z * 0.5;
                  else
                     Z := Z * 2.0;
                  end if;
                  --  Keep the rescaled Z inside the bracket: in the standard
                  --  formulation y < 0 occurs on the deep hyperbolic side,
                  --  where unbounded doubling would overflow cosh inside the
                  --  Stumpff functions (ISS-010).  A bracket pinned at the
                  --  edge exhausts via Max_Iter and reports Converged=False.
                  Z := Real'Max (Z_Low, Real'Min (Z_High, Z));

               when Shrink_Bracket =>
                  if Z > 0.0 then
                     Z_High := Z;
                  else
                     Z_Low := Z;
                  end if;
                  Z := (Z_Low + Z_High) / 2.0;
            end case;
         else
            --  Time of flight for this Z: chi = sqrt(y/C(z)),
            --  sqrt(mu)*TOF = chi**3*S(z) + A*sqrt(y)  (C_Z > 0 guaranteed
            --  by the Compute_Y guard above)
            declare
               Chi : constant Real := Sqrt (Y / C_Z);
               Tof_Computed : Real;
            begin
               Tof_Computed := (Chi**3 * S_Z + A_Param * Sqrt (Y)) / Sqrt_Mu;
               F_Z := Tof_Computed - T;

               --  Check convergence.  The tolerance is applied relative to
               --  the requested time of flight (floored at 1 second): an
               --  absolute test cannot be met once one ulp of T itself
               --  exceeds the tolerance (e.g. ulp(20000 s) ~ 3.6e-12 s
               --  already exceeds the 1.0e-12 default), which made every
               --  long transfer spuriously non-convergent.
               exit when abs (F_Z) < Tolerance * Real'Max (1.0, T);

               --  Update Z using bisection.  On an increasing branch a
               --  too-small computed TOF (F_Z < 0) moves Z_Low up; on the
               --  decreasing left branch of a multi-rev band the predicate
               --  is reversed (larger TOF lies at smaller Z).
               if (F_Z < 0.0) = Increasing then
                  Z_Low := Z;
               else
                  Z_High := Z;
               end if;

               Z := (Z_Low + Z_High) / 2.0;
            end;
         end if;

         Iter := Iter + 1;
         if Iter >= Max_Iter then
            Result.Iterations := Iter;
            return Result;
         end if;
      end loop;

      --  C_Z, S_Z and Y still hold the values of the converged iteration
      --  (same Z), so no recomputation is needed; Y >= 0 is guaranteed here.

      --  Semi-major axis: z = chi**2 / a with chi**2 = y/C(z), so
      --  a = y / (z * C(z)).  Z ~ 0 is the parabolic boundary (a -> inf):
      --  guard the division (ISS-010).  Hyperbolic roots (Z < 0) yield
      --  a < 0 and are rejected by the positivity gate below, per the Post
      --  contract on Solve_Lambert.
      declare
         Denom : constant Real := Z * C_Z;
      begin
         if abs (Denom) < Small_Threshold then
            Result.Iterations := Iter;
            return Result;
         end if;
         A := Y / Denom;
      end;

      --  f and g functions.  G_Func -> 0 for near-degenerate transfers
      --  (A -> 0), so guard it before dividing (ISS-010).
      F_Func := 1.0 - Y / R1_Mag;
      G_Func := A_Param * Sqrt (Y / Mu_Val);
      G_Dot := 1.0 - Y / R2_Mag;

      if abs (G_Func) < Small_Threshold then
         Result.Iterations := Iter;
         return Result;
      end if;

      --  Velocity vectors
      Result.V1 := (1.0 / G_Func) * (R2 - F_Func * R1);
      Result.V2 := (1.0 / G_Func) * (G_Dot * R2 - R1);

      --  Store orbit parameters
      Result.A := Distance_Km (A);
      Result.Iterations := Iter;

      --  Finiteness and positivity gate (ISS-010): only report convergence
      --  when every velocity component is finite ('Valid is False for NaN
      --  and infinities) and the semi-major axis is positive, as required
      --  by the Post contract on Solve_Lambert.
      Result.Converged :=
         Result.V1 (1)'Valid and then Result.V1 (2)'Valid
         and then Result.V1 (3)'Valid
         and then Result.V2 (1)'Valid and then Result.V2 (2)'Valid
         and then Result.V2 (3)'Valid
         and then Result.A'Valid and then Real (Result.A) > 0.0;

      if Result.Converged then
         Result.E := Eccentricity (R1, Result.V1, Mu);
      end if;

      return Result;
   end Solve_Lambert_Core;

   ---------------------------------------------------------------------------
   -- Lambert Solver
   ---------------------------------------------------------------------------

   function Solve_Lambert (R1        : Position_Vector;
                           R2        : Position_Vector;
                           Tof       : Time_Seconds;
                           Mu        : Gravitational_Parameter;
                           Long_Way  : Boolean := False;
                           Tolerance : Real := Default_Tolerance) return Lambert_Result is
   begin
      --  Degenerate (collinear, ~180 degree) geometry leaves the transfer
      --  plane undefined; per docs/specs/05-lambert.md this must raise
      --  Invalid_Orbit.  (Solve_Lambert_Multi pre-guards this case and
      --  returns an empty solution array instead; that behavior is kept.)
      if Is_Degenerate_Transfer (R1, R2) then
         raise Invalid_Orbit with
            "Solve_Lambert: degenerate 180-degree (collinear) transfer geometry";
      end if;

      return Solve_Lambert_Core
         (R1, R2, Tof, Mu, Long_Way,
          Z_Low_Init  => Z_Bound_Hyperbolic,
          Z_High_Init => Z_Bound_Elliptic,
          Z_Init      => 0.0,
          Policy      => Rescale_Toward_Parabolic,
          Increasing  => True,
          Tolerance   => Tolerance);
   end Solve_Lambert;

   --  Internal: solve within a specific Z bracket over which TOF is
   --  monotone; Increasing gives the direction (False on the decreasing
   --  left branch of a multi-revolution band)
   function Solve_Lambert_Bounded (R1         : Position_Vector;
                                   R2         : Position_Vector;
                                   Tof        : Time_Seconds;
                                   Mu         : Gravitational_Parameter;
                                   Long_Way   : Boolean;
                                   Z_Low_In   : Real;
                                   Z_High_In  : Real;
                                   Increasing : Boolean := True;
                                   Tolerance  : Real := Default_Tolerance) return Lambert_Result is
   begin
      return Solve_Lambert_Core
         (R1, R2, Tof, Mu, Long_Way,
          Z_Low_Init  => Z_Low_In,
          Z_High_Init => Z_High_In,
          Z_Init      => (Z_Low_In + Z_High_In) / 2.0,
          Policy      => Shrink_Bracket,
          Increasing  => Increasing,
          Tolerance   => Tolerance);
   end Solve_Lambert_Bounded;

   function Solve_Lambert_Multi (R1       : Position_Vector;
                                 R2       : Position_Vector;
                                 Tof      : Time_Seconds;
                                 Mu       : Gravitational_Parameter;
                                 Max_Revs : Natural := 0;
                                 Long_Way : Boolean := False) return Lambert_Solution_Array is

      --  Capacity: 1 zero-rev solution plus at most 2 per N-rev band (TOF
      --  is U-shaped over each true band, so a band contributes 0 or 2
      --  roots; coincident roots are merged by Add_Unique below)
      Max_Solutions : constant Natural := 1 + 2 * Max_Revs;
      Temp_Results : array (0 .. Max_Solutions - 1) of Lambert_Result;
      Solution_Count : Natural := 0;

      --  Two results closer than this in departure velocity are the same
      --  root found twice (e.g. a requested TOF at a band minimum, where
      --  the two branch roots coalesce); relative to |v1|, floored at
      --  1 km/s so near-zero velocities compare absolutely
      Duplicate_V1_Tol : constant Real := 1.0e-6;

      R_Sum   : Real;
      A_Param : Real;
      Sqrt_Mu : constant Real := Sqrt (Real (Mu));
      T       : constant Real := Real (Tof);

      --  Append Candidate unless it duplicates an already-found root
      procedure Add_Unique (Candidate : Lambert_Result) is
      begin
         for I in 0 .. Solution_Count - 1 loop
            if Magnitude (Temp_Results (I).V1 - Candidate.V1)
               <= Duplicate_V1_Tol * Real'Max (1.0, Magnitude (Candidate.V1))
            then
               return;
            end if;
         end loop;
         Temp_Results (Solution_Count) := Candidate;
         Solution_Count := Solution_Count + 1;
      end Add_Unique;

   begin
      --  Check for degenerate case
      if Is_Degenerate_Transfer (R1, R2) then
         --  180-degree transfer: return empty or handle specially
         declare
            Empty_Result : Lambert_Solution_Array (1 .. 0);
         begin
            return Empty_Result;
         end;
      end if;

      Compute_Transfer_Geometry (R1, R2, Long_Way, R_Sum, A_Param);

      --  Zero-revolution solution: the existing single-revolution solver
      --  over the full bracket (z < 4*pi**2)
      declare
         Zero_Rev : constant Lambert_Result :=
            Solve_Lambert (R1, R2, Tof, Mu, Long_Way);
      begin
         if Zero_Rev.Converged then
            Add_Unique (Zero_Rev);
         end if;
      end;

      --  N-revolution bands: locate the interior TOF minimum of each true
      --  band z in (4*pi**2*N**2, 4*pi**2*(N+1)**2); when the requested
      --  TOF is reachable, bisect each monotone branch separately -
      --  [Z_Lo, Z_Min] with the reversed (decreasing) predicate and
      --  [Z_Min, Z_Hi] with the standard increasing one
      for N in 1 .. Max_Revs loop
         declare
            Z_Lo, Z_Hi, Z_Min, Tof_Min : Real;
            Min_Ok : Boolean;
         begin
            Locate_Band_Minimum
               (N, R_Sum, A_Param, Sqrt_Mu, Z_Lo, Z_Hi, Z_Min, Tof_Min, Min_Ok);

            if Min_Ok and then T >= Tof_Min then
               declare
                  Left : constant Lambert_Result := Solve_Lambert_Bounded
                     (R1, R2, Tof, Mu, Long_Way,
                      Z_Low_In   => Z_Lo,
                      Z_High_In  => Z_Min,
                      Increasing => False);
                  Right : constant Lambert_Result := Solve_Lambert_Bounded
                     (R1, R2, Tof, Mu, Long_Way,
                      Z_Low_In   => Z_Min,
                      Z_High_In  => Z_Hi,
                      Increasing => True);
               begin
                  if Left.Converged then
                     Add_Unique (Left);
                  end if;
                  if Right.Converged then
                     Add_Unique (Right);
                  end if;
               end;
            end if;
         end;
      end loop;

      --  Return only the valid solutions
      declare
         Final_Results : Lambert_Solution_Array (0 .. Solution_Count - 1);
      begin
         for I in 0 .. Solution_Count - 1 loop
            Final_Results (I) := Temp_Results (I);
         end loop;
         return Final_Results;
      end;
   end Solve_Lambert_Multi;

   ---------------------------------------------------------------------------
   -- Utility Functions
   ---------------------------------------------------------------------------

   function Transfer_Angle (R1 : Position_Vector;
                            R2 : Position_Vector;
                            Long_Way : Boolean := False) return Angle_Radians is
      Cos_Angle : Real;
      Angle_Val : Real;
   begin
      Cos_Angle := Dot (R1, R2) / (Magnitude (R1) * Magnitude (R2));

      if Cos_Angle > 1.0 then
         Cos_Angle := 1.0;
      elsif Cos_Angle < -1.0 then
         Cos_Angle := -1.0;
      end if;

      Angle_Val := Arccos (Cos_Angle);

      if Long_Way then
         Angle_Val := Two_Pi - Angle_Val;
      end if;

      return Angle_Radians (Angle_Val);
   end Transfer_Angle;

   function Minimum_Energy_Tof (R1 : Position_Vector;
                                R2 : Position_Vector;
                                Mu : Gravitational_Parameter;
                                Long_Way : Boolean := False) return Time_Seconds is
      R1_Mag : constant Real := Magnitude (R1);
      R2_Mag : constant Real := Magnitude (R2);
      Cos_Dnu : Real;
      C_Chord, S : Real;
      Way_Sign : Real;
      Tof_Min : Real;
   begin
      Cos_Dnu := Dot (R1, R2) / (R1_Mag * R2_Mag);
      if Cos_Dnu > 1.0 then
         Cos_Dnu := 1.0;
      elsif Cos_Dnu < -1.0 then
         Cos_Dnu := -1.0;
      end if;

      C_Chord := Sqrt (R1_Mag**2 + R2_Mag**2 - 2.0 * R1_Mag * R2_Mag * Cos_Dnu);
      S := (R1_Mag + R2_Mag + C_Chord) / 2.0;

      --  Parabolic (minimum) time of flight, Barker/Battin form:
      --     t_p = (1/3) * sqrt(2/mu) * (s**1.5 - sign * (s - c)**1.5)
      --  with sign = +1 for the short way (transfer angle < 180 deg) and
      --  -1 for the long way.  The former code dropped the (s - c)**1.5
      --  term entirely, overstating the short-way bound (by ~50% for
      --  Vallado 7-1 geometry) and making Solution_Exists reject
      --  genuinely solvable elliptic transfers.
      Way_Sign := (if Long_Way then -1.0 else 1.0);

      --  s - c = r1 + r2 - c >= 0 by the triangle inequality; clamp the
      --  rounding residue of near-degenerate geometry before **1.5
      Tof_Min := Sqrt (2.0 / Real (Mu)) / 3.0
                 * (S ** 1.5 - Way_Sign * Real'Max (0.0, S - C_Chord) ** 1.5);

      return Time_Seconds (Tof_Min);
   end Minimum_Energy_Tof;

   --  A zero-revolution elliptic solution exists exactly when the
   --  requested TOF is at or above the way-specific parabolic bound
   function Solution_Exists (R1       : Position_Vector;
                             R2       : Position_Vector;
                             Tof      : Time_Seconds;
                             Mu       : Gravitational_Parameter;
                             Long_Way : Boolean := False) return Boolean is
      Tof_Min : constant Time_Seconds := Minimum_Energy_Tof (R1, R2, Mu, Long_Way);
   begin
      return Real (Tof) >= Real (Tof_Min);
   end Solution_Exists;

   ---------------------------------------------------------------------------
   -- Orbit from Lambert Solution
   ---------------------------------------------------------------------------

   function Get_Transfer_Elements (R1     : Position_Vector;
                                   Result : Lambert_Result;
                                   Mu     : Gravitational_Parameter) return Orbital_Elements is
   begin
      return State_To_Elements (R1, Result.V1, Mu);
   end Get_Transfer_Elements;

   function Departure_Delta_V (V_Initial : Velocity_Vector;
                               Result    : Lambert_Result) return Velocity_Km_S is
      Delta_V : constant Vector_3D := Result.V1 - V_Initial;
   begin
      return Velocity_Km_S (Magnitude (Delta_V));
   end Departure_Delta_V;

   function Arrival_Delta_V (V_Final : Velocity_Vector;
                             Result  : Lambert_Result) return Velocity_Km_S is
      Delta_V : constant Vector_3D := V_Final - Result.V2;
   begin
      return Velocity_Km_S (Magnitude (Delta_V));
   end Arrival_Delta_V;

   function Total_Delta_V (V_Initial : Velocity_Vector;
                           V_Final   : Velocity_Vector;
                           Result    : Lambert_Result) return Velocity_Km_S is
   begin
      return Velocity_Km_S (Real (Departure_Delta_V (V_Initial, Result)) +
                            Real (Arrival_Delta_V (V_Final, Result)));
   end Total_Delta_V;

   ---------------------------------------------------------------------------
   -- Multi-Revolution Utilities
   ---------------------------------------------------------------------------

   function Min_Tof_N_Revs (R1       : Position_Vector;
                            R2       : Position_Vector;
                            Mu       : Gravitational_Parameter;
                            N_Revs   : Natural;
                            Long_Way : Boolean := False) return Time_Seconds is
   begin
      --  N = 0: the way-specific parabolic lower bound on elliptic TOF
      if N_Revs = 0 then
         return Minimum_Energy_Tof (R1, R2, Mu, Long_Way);
      end if;

      --  N >= 1: TOF at the interior minimum of the true N-rev band,
      --  located with the same machinery Solve_Lambert_Multi uses, so the
      --  reachability threshold and the returned solutions cannot disagree
      declare
         R_Sum, A_Param : Real;
         Z_Lo, Z_Hi, Z_Min, Tof_Min : Real;
         Min_Ok : Boolean;
      begin
         Compute_Transfer_Geometry (R1, R2, Long_Way, R_Sum, A_Param);
         Locate_Band_Minimum (N_Revs, R_Sum, A_Param, Sqrt (Real (Mu)),
                              Z_Lo, Z_Hi, Z_Min, Tof_Min, Min_Ok);

         if Min_Ok then
            return Time_Seconds (Tof_Min);
         end if;

         --  Conservative fallback (unreachable for non-degenerate
         --  geometry, where the band interior is fully computable):
         --  historic estimate of parabolic bound plus N periods of the
         --  minimum-energy ellipse a_min = s/2
         declare
            R1_Mag  : constant Real := Magnitude (R1);
            R2_Mag  : constant Real := Magnitude (R2);
            Cos_Dnu : constant Real :=
               Real'Max (-1.0, Real'Min (1.0,
                  Dot (R1, R2) / (R1_Mag * R2_Mag)));
            C_Chord : constant Real :=
               Sqrt (R1_Mag**2 + R2_Mag**2
                     - 2.0 * R1_Mag * R2_Mag * Cos_Dnu);
            A_Min : constant Real := (R1_Mag + R2_Mag + C_Chord) / 4.0;
            T_Period : constant Real :=
               Two_Pi * Sqrt (A_Min**3 / Real (Mu));
         begin
            return Time_Seconds
               (Real (Minimum_Energy_Tof (R1, R2, Mu, Long_Way))
                + Real (N_Revs) * T_Period);
         end;
      end;
   end Min_Tof_N_Revs;

   function Is_Degenerate_Transfer (R1 : Position_Vector;
                                    R2 : Position_Vector) return Boolean is
      --  Check if positions are collinear (180-degree transfer)
      Cross_Prod : constant Vector_3D := Cross (R1, R2);
      Cross_Mag : constant Real := Magnitude (Cross_Prod);
      R1_Mag : constant Real := Magnitude (R1);
      R2_Mag : constant Real := Magnitude (R2);
   begin
      --  |R1 x R2| = |R1| |R2| sin(theta)
      --  If sin(theta) ≈ 0, then theta ≈ 0 or theta ≈ 180
      --  Uses Degenerate_Transfer_Threshold from Types (ISS-065)
      if Cross_Mag < Degenerate_Transfer_Threshold * R1_Mag * R2_Mag then
         --  Check if 180-degree (opposite directions)
         declare
            Dot_Prod : constant Real := Dot (R1, R2);
         begin
            --  If dot product < 0, positions are roughly opposite
            return Dot_Prod < 0.0;
         end;
      end if;

      return False;
   end Is_Degenerate_Transfer;

   function Count_Multi_Rev_Solutions (R1       : Position_Vector;
                                       R2       : Position_Vector;
                                       Tof      : Time_Seconds;
                                       Mu       : Gravitational_Parameter;
                                       Max_Revs : Natural := 5) return Natural is
      --  Run the SAME enumeration Solve_Lambert_Multi performs (short way,
      --  Long_Way = False) and count the roots it actually finds, so the
      --  advertised count and the returned solution array cannot disagree
      Solutions : constant Lambert_Solution_Array :=
         Solve_Lambert_Multi (R1, R2, Tof, Mu, Max_Revs, Long_Way => False);
   begin
      return Solutions'Length;
   end Count_Multi_Rev_Solutions;

end Hale_Orbital.Lambert;
