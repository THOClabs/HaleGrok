-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Vector Operations Body
-------------------------------------------------------------------------------

with Ada.Numerics.Generic_Elementary_Functions;

package body Hale_Orbital.Vectors
   with SPARK_Mode => Off  --  Body uses generic instantiation
is

   --  Instantiate elementary functions for our Real type
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   ---------------------------------------------------------------------------
   -- Basic Vector Arithmetic
   ---------------------------------------------------------------------------

   function "+" (A, B : Vector_3D) return Vector_3D is
   begin
      return (A (1) + B (1), A (2) + B (2), A (3) + B (3));
   end "+";

   function "-" (A, B : Vector_3D) return Vector_3D is
   begin
      return (A (1) - B (1), A (2) - B (2), A (3) - B (3));
   end "-";

   function "-" (V : Vector_3D) return Vector_3D is
   begin
      return (-V (1), -V (2), -V (3));
   end "-";

   function "*" (S : Real; V : Vector_3D) return Vector_3D is
   begin
      return (S * V (1), S * V (2), S * V (3));
   end "*";

   function "*" (V : Vector_3D; S : Real) return Vector_3D is
   begin
      return (V (1) * S, V (2) * S, V (3) * S);
   end "*";

   function "/" (V : Vector_3D; S : Real) return Vector_3D is
   begin
      return (V (1) / S, V (2) / S, V (3) / S);
   end "/";

   ---------------------------------------------------------------------------
   -- Vector Products
   ---------------------------------------------------------------------------

   function Dot (A, B : Vector_3D) return Real is
   begin
      return A (1) * B (1) + A (2) * B (2) + A (3) * B (3);
   end Dot;

   function Cross (A, B : Vector_3D) return Vector_3D is
   begin
      return (A (2) * B (3) - A (3) * B (2),
              A (3) * B (1) - A (1) * B (3),
              A (1) * B (2) - A (2) * B (1));
   end Cross;

   ---------------------------------------------------------------------------
   -- Vector Properties
   ---------------------------------------------------------------------------

   function Magnitude_Squared (V : Vector_3D) return Real is
   begin
      return V (1) * V (1) + V (2) * V (2) + V (3) * V (3);
   end Magnitude_Squared;

   function Magnitude (V : Vector_3D) return Real is
   begin
      return Sqrt (Magnitude_Squared (V));
   end Magnitude;

   function Normalize (V : Vector_3D) return Vector_3D is
      Mag : constant Real := Magnitude (V);
   begin
      if Mag < 1.0e-15 then
         raise Physical_Error with "Cannot normalize zero vector";
      end if;
      return V / Mag;
   end Normalize;

   function Is_Zero (V : Vector_3D; Tolerance : Real := 1.0e-12) return Boolean is
   begin
      return Magnitude_Squared (V) < Tolerance * Tolerance;
   end Is_Zero;

   function Are_Parallel (A, B : Vector_3D; Tolerance : Real := 1.0e-12) return Boolean is
      Cross_Product : constant Vector_3D := Cross (A, B);
   begin
      return Is_Zero (Cross_Product, Tolerance);
   end Are_Parallel;

   function Are_Perpendicular (A, B : Vector_3D; Tolerance : Real := 1.0e-12) return Boolean is
   begin
      return abs (Dot (A, B)) < Tolerance;
   end Are_Perpendicular;

   ---------------------------------------------------------------------------
   -- Angle Operations
   ---------------------------------------------------------------------------

   function Angle_Between (A, B : Vector_3D) return Angle_Radians is
      Mag_A : constant Real := Magnitude (A);
      Mag_B : constant Real := Magnitude (B);
      Cos_Angle : Real;
   begin
      if Mag_A < 1.0e-15 or Mag_B < 1.0e-15 then
         raise Physical_Error with "Cannot compute angle with zero vector";
      end if;

      Cos_Angle := Dot (A, B) / (Mag_A * Mag_B);

      --  Clamp to [-1, 1] to handle numerical errors
      if Cos_Angle > 1.0 then
         Cos_Angle := 1.0;
      elsif Cos_Angle < -1.0 then
         Cos_Angle := -1.0;
      end if;

      return Angle_Radians (Arccos (Cos_Angle));
   end Angle_Between;

   function Project (A : Vector_3D; Onto_B : Vector_3D) return Vector_3D is
      B_Mag_Sq : constant Real := Magnitude_Squared (Onto_B);
   begin
      if B_Mag_Sq < 1.0e-15 then
         raise Physical_Error with "Cannot project onto zero vector";
      end if;
      return (Dot (A, Onto_B) / B_Mag_Sq) * Onto_B;
   end Project;

   function Perpendicular_Component (A : Vector_3D; To_B : Vector_3D) return Vector_3D is
   begin
      return A - Project (A, To_B);
   end Perpendicular_Component;

   ---------------------------------------------------------------------------
   -- Rotation Operations
   ---------------------------------------------------------------------------

   function Rotate_X (V : Vector_3D; Angle : Angle_Radians) return Vector_3D is
      C : constant Real := Cos (Real (Angle));
      S : constant Real := Sin (Real (Angle));
   begin
      return (V (1),
              C * V (2) - S * V (3),
              S * V (2) + C * V (3));
   end Rotate_X;

   function Rotate_Y (V : Vector_3D; Angle : Angle_Radians) return Vector_3D is
      C : constant Real := Cos (Real (Angle));
      S : constant Real := Sin (Real (Angle));
   begin
      return (C * V (1) + S * V (3),
              V (2),
              -S * V (1) + C * V (3));
   end Rotate_Y;

   function Rotate_Z (V : Vector_3D; Angle : Angle_Radians) return Vector_3D is
      C : constant Real := Cos (Real (Angle));
      S : constant Real := Sin (Real (Angle));
   begin
      return (C * V (1) - S * V (2),
              S * V (1) + C * V (2),
              V (3));
   end Rotate_Z;

   function Rotate_About_Axis (V     : Vector_3D;
                                Axis  : Vector_3D;
                                Angle : Angle_Radians) return Vector_3D is
      --  Rodrigues' rotation formula
      K : constant Vector_3D := Normalize (Axis);
      C : constant Real := Cos (Real (Angle));
      S : constant Real := Sin (Real (Angle));
      K_Cross_V : constant Vector_3D := Cross (K, V);
      K_Dot_V   : constant Real := Dot (K, V);
   begin
      return C * V + S * K_Cross_V + (1.0 - C) * K_Dot_V * K;
   end Rotate_About_Axis;

   ---------------------------------------------------------------------------
   -- Coordinate Transformations
   ---------------------------------------------------------------------------

   function Safe_Atan2 (Y, X : Real) return Real is
   begin
      if abs (X) < 1.0e-15 and abs (Y) < 1.0e-15 then
         return 0.0;
      else
         return Arctan (Y, X);
      end if;
   end Safe_Atan2;

   procedure Cartesian_To_Spherical (V     : in  Vector_3D;
                                     R     : out Real;
                                     Theta : out Angle_Radians;
                                     Phi   : out Angle_Radians) is
      Rho : Real;
   begin
      R := Magnitude (V);

      if R < 1.0e-15 then
         Theta := 0.0;
         Phi := 0.0;
         return;
      end if;

      --  Polar angle from +Z axis
      Theta := Angle_Radians (Arccos (V (3) / R));

      --  Azimuth from +X in XY plane
      Rho := Sqrt (V (1) * V (1) + V (2) * V (2));
      if Rho < 1.0e-15 then
         Phi := 0.0;
      else
         Phi := Angle_Radians (Safe_Atan2 (V (2), V (1)));
      end if;
   end Cartesian_To_Spherical;

   function Spherical_To_Cartesian (R     : Real;
                                    Theta : Angle_Radians;
                                    Phi   : Angle_Radians) return Vector_3D is
      Sin_Theta : constant Real := Sin (Real (Theta));
   begin
      return (R * Sin_Theta * Cos (Real (Phi)),
              R * Sin_Theta * Sin (Real (Phi)),
              R * Cos (Real (Theta)));
   end Spherical_To_Cartesian;

end Hale_Orbital.Vectors;
