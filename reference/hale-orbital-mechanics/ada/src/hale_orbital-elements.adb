-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Orbital Elements Body
-------------------------------------------------------------------------------

with Ada.Numerics.Generic_Elementary_Functions;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Vectors;   use Hale_Orbital.Vectors;
with Hale_Orbital.Twobody;   use Hale_Orbital.Twobody;

package body Hale_Orbital.Elements
   with SPARK_Mode => Off  --  Body uses generic instantiation
is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   --  Internal helper for safe atan2
   function Safe_Atan2 (Y, X : Real) return Real is
   begin
      if abs (X) < 1.0e-15 and abs (Y) < 1.0e-15 then
         return 0.0;
      else
         return Arctan (Y, X);
      end if;
   end Safe_Atan2;

   ---------------------------------------------------------------------------
   -- Angle Normalization
   ---------------------------------------------------------------------------

   function Normalize_Angle (Angle : Angle_Radians) return Angle_Radians is
      Result : Real := Real (Angle);
   begin
      while Result < 0.0 loop
         Result := Result + Two_Pi;
      end loop;
      while Result >= Two_Pi loop
         Result := Result - Two_Pi;
      end loop;
      return Angle_Radians (Result);
   end Normalize_Angle;

   function Normalize_Angle_Symmetric (Angle : Angle_Radians) return Angle_Radians is
      Result : Real := Real (Angle);
   begin
      while Result < -Pi loop
         Result := Result + Two_Pi;
      end loop;
      while Result >= Pi loop
         Result := Result - Two_Pi;
      end loop;
      return Angle_Radians (Result);
   end Normalize_Angle_Symmetric;

   ---------------------------------------------------------------------------
   -- State to Elements Conversion
   ---------------------------------------------------------------------------

   function State_To_Elements (R  : Position_Vector;
                               V  : Velocity_Vector;
                               Mu : Gravitational_Parameter) return Orbital_Elements is
      Elements : Orbital_Elements;

      --  Magnitudes
      R_Mag : constant Real := Magnitude (R);
      V_Mag : constant Real := Magnitude (V);

      --  Angular momentum vector h = r x v
      H_Vec : constant Vector_3D := Cross (R, V);
      H_Mag : constant Real := Magnitude (H_Vec);

      --  Node vector n = K x h (K is unit z)
      N_Vec : constant Vector_3D := Cross (Unit_Z, H_Vec);
      N_Mag : constant Real := Magnitude (N_Vec);

      --  Eccentricity vector
      E_Vec : constant Vector_3D := Eccentricity_Vector (R, V, Mu);
      E_Mag : constant Real := Magnitude (E_Vec);

      --  Specific energy
      Energy : constant Real := V_Mag**2 / 2.0 - Real (Mu) / R_Mag;

      --  Semi-major axis
      A : Real;

      --  Working variables
      Cos_I, Cos_Nu, R_Dot_V : Real;

   begin
      --  Check for degenerate case
      if R_Mag < 1.0e-10 then
         raise Physical_Error with "Position magnitude too small";
      end if;
      if H_Mag < 1.0e-10 then
         raise Physical_Error with "Angular momentum too small (radial orbit)";
      end if;

      --  Semi-major axis from energy
      --  a = -mu / (2*epsilon) for ellipse
      --  a = mu / (2*|epsilon|) for hyperbola (negative by convention)
      if abs (Energy) < 1.0e-15 then
         --  Parabolic orbit
         A := Real'Last;  -- Infinite semi-major axis
         Elements.Semi_Major_Axis := Distance_Km (1.0e12);  -- Large value
      else
         A := -Real (Mu) / (2.0 * Energy);
         Elements.Semi_Major_Axis := Distance_Km (A);
      end if;

      --  Eccentricity
      Elements.Eccentricity := E_Mag;

      --  Inclination: i = arccos(h_z / |h|)
      Cos_I := H_Vec (3) / H_Mag;
      --  Clamp for numerical safety
      if Cos_I > 1.0 then
         Cos_I := 1.0;
      elsif Cos_I < -1.0 then
         Cos_I := -1.0;
      end if;
      Elements.Inclination := Angle_Radians (Arccos (Cos_I));

      --  Right Ascension of Ascending Node (RAAN)
      --  For equatorial orbits (i=0 or i=180), RAAN is undefined - set to 0
      if N_Mag < 1.0e-10 then
         Elements.RAAN := 0.0;
      else
         Elements.RAAN := Angle_Radians (Safe_Atan2 (N_Vec (2), N_Vec (1)));
         Elements.RAAN := Normalize_Angle (Elements.RAAN);
      end if;

      --  Argument of Periapsis
      --  For circular orbits, omega is undefined - set to 0
      --  For equatorial non-circular, use longitude of periapsis
      if E_Mag < Circular_Threshold then
         --  Circular orbit
         Elements.Argument_Of_Periapsis := 0.0;
      elsif N_Mag < 1.0e-10 then
         --  Equatorial but not circular: use angle from X-axis
         Elements.Argument_Of_Periapsis := Angle_Radians (Safe_Atan2 (E_Vec (2), E_Vec (1)));
         if H_Vec (3) < 0.0 then
            --  Retrograde equatorial
            Elements.Argument_Of_Periapsis := Angle_Radians (Two_Pi - Real (Elements.Argument_Of_Periapsis));
         end if;
         Elements.Argument_Of_Periapsis := Normalize_Angle (Elements.Argument_Of_Periapsis);
      else
         --  General case: angle from node vector to eccentricity vector
         declare
            Cos_Omega : Real := Dot (N_Vec, E_Vec) / (N_Mag * E_Mag);
         begin
            if Cos_Omega > 1.0 then
               Cos_Omega := 1.0;
            elsif Cos_Omega < -1.0 then
               Cos_Omega := -1.0;
            end if;
            Elements.Argument_Of_Periapsis := Angle_Radians (Arccos (Cos_Omega));
            --  Quadrant check: if e_z < 0, omega is in [pi, 2*pi]
            if E_Vec (3) < 0.0 then
               Elements.Argument_Of_Periapsis := Angle_Radians (Two_Pi - Real (Elements.Argument_Of_Periapsis));
            end if;
         end;
      end if;

      --  True Anomaly
      R_Dot_V := Dot (R, V);

      if E_Mag < Circular_Threshold then
         --  Circular orbit: measure from node vector (or X-axis if equatorial)
         if N_Mag < 1.0e-10 then
            --  Circular equatorial: true longitude
            Elements.True_Anomaly := Angle_Radians (Safe_Atan2 (R (2), R (1)));
         else
            --  Circular inclined: argument of latitude
            declare
               Cos_U : Real := Dot (N_Vec, R) / (N_Mag * R_Mag);
            begin
               if Cos_U > 1.0 then
                  Cos_U := 1.0;
               elsif Cos_U < -1.0 then
                  Cos_U := -1.0;
               end if;
               Elements.True_Anomaly := Angle_Radians (Arccos (Cos_U));
               if R (3) < 0.0 then
                  Elements.True_Anomaly := Angle_Radians (Two_Pi - Real (Elements.True_Anomaly));
               end if;
            end;
         end if;
      else
         --  General case: angle from eccentricity vector to position
         Cos_Nu := Dot (E_Vec, R) / (E_Mag * R_Mag);
         if Cos_Nu > 1.0 then
            Cos_Nu := 1.0;
         elsif Cos_Nu < -1.0 then
            Cos_Nu := -1.0;
         end if;
         Elements.True_Anomaly := Angle_Radians (Arccos (Cos_Nu));
         --  Quadrant check: if r.v < 0, we're past apoapsis
         if R_Dot_V < 0.0 then
            Elements.True_Anomaly := Angle_Radians (Two_Pi - Real (Elements.True_Anomaly));
         end if;
      end if;

      Elements.True_Anomaly := Normalize_Angle (Elements.True_Anomaly);

      return Elements;
   end State_To_Elements;

   function State_To_Elements (State : State_Vector;
                               Mu    : Gravitational_Parameter) return Orbital_Elements is
   begin
      return State_To_Elements (State.Position, State.Velocity, Mu);
   end State_To_Elements;

   ---------------------------------------------------------------------------
   -- Elements to State Conversion
   ---------------------------------------------------------------------------

   function Elements_To_State (Elements : Orbital_Elements;
                               Mu       : Gravitational_Parameter) return State_Vector is
      State : State_Vector;

      A  : constant Real := Real (Elements.Semi_Major_Axis);
      E  : constant Real := Elements.Eccentricity;
      I  : constant Real := Real (Elements.Inclination);
      Om : constant Real := Real (Elements.RAAN);
      W  : constant Real := Real (Elements.Argument_Of_Periapsis);
      Nu : constant Real := Real (Elements.True_Anomaly);

      --  Semi-latus rectum
      P : Real;

      --  Position and velocity in perifocal frame
      R_PQW, V_PQW : Vector_3D;

      --  Radius magnitude
      R_Mag : Real;

      --  Rotation matrix components
      Cos_Om, Sin_Om : Real;
      Cos_I, Sin_I   : Real;
      Cos_W, Sin_W   : Real;
      Cos_Nu, Sin_Nu : Real;

      --  Angular momentum
      H : Real;

   begin
      --  Validate eccentricity
      if E < 0.0 then
         raise Invalid_Orbit with "Eccentricity cannot be negative";
      end if;

      --  Compute semi-latus rectum
      if E < 1.0 then
         P := A * (1.0 - E * E);
      else
         --  Hyperbolic: a is negative, p = a(1-e^2) = |a|(e^2-1)
         P := abs (A) * (E * E - 1.0);
      end if;

      if P <= 0.0 then
         raise Invalid_Orbit with "Semi-latus rectum must be positive";
      end if;

      --  Radius at true anomaly
      Cos_Nu := Cos (Nu);
      Sin_Nu := Sin (Nu);
      R_Mag := P / (1.0 + E * Cos_Nu);

      if R_Mag <= 0.0 then
         raise Physical_Error with "Invalid radius calculated";
      end if;

      --  Position in perifocal frame (PQW)
      R_PQW := (R_Mag * Cos_Nu, R_Mag * Sin_Nu, 0.0);

      --  Angular momentum magnitude
      H := Sqrt (Real (Mu) * P);

      --  Velocity in perifocal frame
      V_PQW := ((-Real (Mu) / H) * Sin_Nu,
                (Real (Mu) / H) * (E + Cos_Nu),
                0.0);

      --  Transform to inertial frame using rotation matrices
      --  R_eci = R3(-Om) * R1(-i) * R3(-w) * R_pqw
      Cos_Om := Cos (Om);
      Sin_Om := Sin (Om);
      Cos_I := Cos (I);
      Sin_I := Sin (I);
      Cos_W := Cos (W);
      Sin_W := Sin (W);

      --  Combined rotation (perifocal to inertial)
      State.Position (1) := (Cos_Om * Cos_W - Sin_Om * Sin_W * Cos_I) * R_PQW (1) +
                            (-Cos_Om * Sin_W - Sin_Om * Cos_W * Cos_I) * R_PQW (2);
      State.Position (2) := (Sin_Om * Cos_W + Cos_Om * Sin_W * Cos_I) * R_PQW (1) +
                            (-Sin_Om * Sin_W + Cos_Om * Cos_W * Cos_I) * R_PQW (2);
      State.Position (3) := (Sin_W * Sin_I) * R_PQW (1) +
                            (Cos_W * Sin_I) * R_PQW (2);

      State.Velocity (1) := (Cos_Om * Cos_W - Sin_Om * Sin_W * Cos_I) * V_PQW (1) +
                            (-Cos_Om * Sin_W - Sin_Om * Cos_W * Cos_I) * V_PQW (2);
      State.Velocity (2) := (Sin_Om * Cos_W + Cos_Om * Sin_W * Cos_I) * V_PQW (1) +
                            (-Sin_Om * Sin_W + Cos_Om * Cos_W * Cos_I) * V_PQW (2);
      State.Velocity (3) := (Sin_W * Sin_I) * V_PQW (1) +
                            (Cos_W * Sin_I) * V_PQW (2);

      return State;
   end Elements_To_State;

   function Elements_To_Position (Elements : Orbital_Elements;
                                  Mu       : Gravitational_Parameter) return Position_Vector is
   begin
      return Elements_To_State (Elements, Mu).Position;
   end Elements_To_Position;

   function Elements_To_Velocity (Elements : Orbital_Elements;
                                  Mu       : Gravitational_Parameter) return Velocity_Vector is
   begin
      return Elements_To_State (Elements, Mu).Velocity;
   end Elements_To_Velocity;

   ---------------------------------------------------------------------------
   -- Anomaly Conversions
   ---------------------------------------------------------------------------

   function True_To_Eccentric_Anomaly (Nu : Angle_Radians;
                                       E  : Real) return Angle_Radians is
      --  tan(E/2) = sqrt((1-e)/(1+e)) * tan(nu/2)
      Beta : Real;
      Ecc_Anom : Real;
   begin
      --  Check for non-elliptic orbit (ISS-033: use threshold for consistency)
      if E > 1.0 - Parabolic_Threshold then
         raise Invalid_Orbit with "Eccentric anomaly undefined for e >= 1";
      end if;

      Beta := Sqrt ((1.0 - E) / (1.0 + E));
      Ecc_Anom := 2.0 * Arctan (Beta * Tan (Real (Nu) / 2.0));

      return Normalize_Angle (Angle_Radians (Ecc_Anom));
   end True_To_Eccentric_Anomaly;

   function Eccentric_To_True_Anomaly (Ecc_Anom : Angle_Radians;
                                       E        : Real) return Angle_Radians is
      --  tan(nu/2) = sqrt((1+e)/(1-e)) * tan(E/2)
      Beta : Real;
      Nu : Real;
   begin
      --  Check for non-elliptic orbit (ISS-033: use threshold for consistency)
      if E > 1.0 - Parabolic_Threshold then
         raise Invalid_Orbit with "True anomaly conversion undefined for e >= 1";
      end if;

      Beta := Sqrt ((1.0 + E) / (1.0 - E));
      Nu := 2.0 * Arctan (Beta * Tan (Real (Ecc_Anom) / 2.0));

      return Normalize_Angle (Angle_Radians (Nu));
   end Eccentric_To_True_Anomaly;

   function Eccentric_To_Mean_Anomaly (Ecc_Anom : Angle_Radians;
                                       E        : Real) return Angle_Radians is
   begin
      --  M = E - e*sin(E)
      return Angle_Radians (Real (Ecc_Anom) - E * Sin (Real (Ecc_Anom)));
   end Eccentric_To_Mean_Anomaly;

   function True_To_Mean_Anomaly (Nu : Angle_Radians;
                                  E  : Real) return Angle_Radians is
      Ecc_Anom : Angle_Radians;
   begin
      Ecc_Anom := True_To_Eccentric_Anomaly (Nu, E);
      return Eccentric_To_Mean_Anomaly (Ecc_Anom, E);
   end True_To_Mean_Anomaly;

   function Mean_To_Eccentric_Anomaly (M         : Angle_Radians;
                                       E         : Real;
                                       Tolerance : Real := Default_Tolerance) return Angle_Radians is
      --  Newton-Raphson iteration for Kepler's equation
      --  E - e*sin(E) = M
      Ecc_Anom : Real := Real (M);  -- Initial guess
      F, F_Prime : Real;
      Iter : Natural := 0;
   begin
      --  Check for non-elliptic orbit (ISS-033: use threshold for consistency)
      if E > 1.0 - Parabolic_Threshold then
         raise Invalid_Orbit with "Kepler's equation undefined for e >= 1";
      end if;

      --  Better initial guess for high eccentricity (ISS-032: use named constant)
      if E > High_Eccentricity_Threshold then
         Ecc_Anom := Pi;
      end if;

      loop
         F := Ecc_Anom - E * Sin (Ecc_Anom) - Real (M);
         F_Prime := 1.0 - E * Cos (Ecc_Anom);

         if abs (F_Prime) < 1.0e-15 then
            raise Convergence_Error with "Kepler solver derivative too small";
         end if;

         Ecc_Anom := Ecc_Anom - F / F_Prime;
         Iter := Iter + 1;

         exit when abs (F) < Tolerance;
         exit when Iter > Default_Max_Iterations;
      end loop;

      if Iter > Default_Max_Iterations then
         raise Convergence_Error with "Kepler solver failed to converge";
      end if;

      return Angle_Radians (Ecc_Anom);
   end Mean_To_Eccentric_Anomaly;

   function Mean_To_True_Anomaly (M         : Angle_Radians;
                                  E         : Real;
                                  Tolerance : Real := Default_Tolerance) return Angle_Radians is
      Ecc_Anom : Angle_Radians;
   begin
      Ecc_Anom := Mean_To_Eccentric_Anomaly (M, E, Tolerance);
      return Eccentric_To_True_Anomaly (Ecc_Anom, E);
   end Mean_To_True_Anomaly;

   ---------------------------------------------------------------------------
   -- Hyperbolic Anomaly Conversions
   ---------------------------------------------------------------------------

   function True_To_Hyperbolic_Anomaly (Nu : Angle_Radians;
                                        E  : Real) return Real is
      --  tanh(H/2) = sqrt((e-1)/(e+1)) * tan(nu/2)
      Beta : Real;
      Tanh_H2 : Real;
   begin
      if E <= 1.0 then
         raise Invalid_Orbit with "Hyperbolic anomaly requires e > 1";
      end if;

      Beta := Sqrt ((E - 1.0) / (E + 1.0));
      Tanh_H2 := Beta * Tan (Real (Nu) / 2.0);

      --  H = 2 * arctanh(tanh_H2)
      --  arctanh(x) = 0.5 * ln((1+x)/(1-x))
      if abs (Tanh_H2) >= 1.0 then
         raise Physical_Error with "Invalid true anomaly for this hyperbola";
      end if;

      return Log ((1.0 + Tanh_H2) / (1.0 - Tanh_H2));
   end True_To_Hyperbolic_Anomaly;

   function Hyperbolic_To_True_Anomaly (H : Real;
                                        E : Real) return Angle_Radians is
      --  tan(nu/2) = sqrt((e+1)/(e-1)) * tanh(H/2)
      Beta : Real;
      Tanh_H2 : Real;
      Nu : Real;
   begin
      if E <= 1.0 then
         raise Invalid_Orbit with "Hyperbolic anomaly requires e > 1";
      end if;

      Beta := Sqrt ((E + 1.0) / (E - 1.0));
      --  tanh(H/2) = (exp(H) - 1) / (exp(H) + 1)
      Tanh_H2 := (Exp (H) - 1.0) / (Exp (H) + 1.0);

      Nu := 2.0 * Arctan (Beta * Tanh_H2);
      return Angle_Radians (Nu);
   end Hyperbolic_To_True_Anomaly;

   function Hyperbolic_To_Mean_Anomaly (H : Real;
                                        E : Real) return Real is
   begin
      --  M = e*sinh(H) - H
      return E * (Exp (H) - Exp (-H)) / 2.0 - H;
   end Hyperbolic_To_Mean_Anomaly;

   ---------------------------------------------------------------------------
   -- Element Validation
   ---------------------------------------------------------------------------

   function Is_Valid (Elements : Orbital_Elements) return Boolean is
   begin
      --  Eccentricity must be non-negative
      if Elements.Eccentricity < 0.0 then
         return False;
      end if;

      --  Semi-major axis must be positive for ellipse, negative for hyperbola
      if Elements.Eccentricity < 1.0 then
         if Real (Elements.Semi_Major_Axis) <= 0.0 then
            return False;
         end if;
      elsif Elements.Eccentricity > 1.0 then
         if Real (Elements.Semi_Major_Axis) >= 0.0 then
            return False;
         end if;
      end if;

      --  Inclination in [0, pi]
      if Real (Elements.Inclination) < 0.0 or Real (Elements.Inclination) > Pi then
         return False;
      end if;

      return True;
   end Is_Valid;

   function Get_Orbit_Type (Elements : Orbital_Elements) return Orbit_Type is
   begin
      return Classify_Orbit (Elements.Eccentricity);
   end Get_Orbit_Type;

end Hale_Orbital.Elements;
