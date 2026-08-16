-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Matrix Operations Body
-------------------------------------------------------------------------------

with Ada.Numerics.Generic_Elementary_Functions;

package body Hale_Orbital.Matrices
   with SPARK_Mode => Off  --  Body uses generic instantiation
is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   ---------------------------------------------------------------------------
   -- Basic Matrix Arithmetic
   ---------------------------------------------------------------------------

   function "+" (A, B : Matrix_3x3) return Matrix_3x3 is
      Result : Matrix_3x3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            Result (I, J) := A (I, J) + B (I, J);
         end loop;
      end loop;
      return Result;
   end "+";

   function "-" (A, B : Matrix_3x3) return Matrix_3x3 is
      Result : Matrix_3x3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            Result (I, J) := A (I, J) - B (I, J);
         end loop;
      end loop;
      return Result;
   end "-";

   function "-" (M : Matrix_3x3) return Matrix_3x3 is
      Result : Matrix_3x3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            Result (I, J) := -M (I, J);
         end loop;
      end loop;
      return Result;
   end "-";

   function "*" (S : Real; M : Matrix_3x3) return Matrix_3x3 is
      Result : Matrix_3x3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            Result (I, J) := S * M (I, J);
         end loop;
      end loop;
      return Result;
   end "*";

   function "*" (M : Matrix_3x3; S : Real) return Matrix_3x3 is
   begin
      return S * M;
   end "*";

   function "*" (A, B : Matrix_3x3) return Matrix_3x3 is
      Result : Matrix_3x3 := (others => (others => 0.0));
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            for K in 1 .. 3 loop
               Result (I, J) := Result (I, J) + A (I, K) * B (K, J);
            end loop;
         end loop;
      end loop;
      return Result;
   end "*";

   function "*" (M : Matrix_3x3; V : Vector_3D) return Vector_3D is
      Result : Vector_3D := (0.0, 0.0, 0.0);
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            Result (I) := Result (I) + M (I, J) * V (J);
         end loop;
      end loop;
      return Result;
   end "*";

   ---------------------------------------------------------------------------
   -- Matrix Properties
   ---------------------------------------------------------------------------

   function Transpose (M : Matrix_3x3) return Matrix_3x3 is
      Result : Matrix_3x3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            Result (I, J) := M (J, I);
         end loop;
      end loop;
      return Result;
   end Transpose;

   function Determinant (M : Matrix_3x3) return Real is
   begin
      return M (1, 1) * (M (2, 2) * M (3, 3) - M (2, 3) * M (3, 2))
           - M (1, 2) * (M (2, 1) * M (3, 3) - M (2, 3) * M (3, 1))
           + M (1, 3) * (M (2, 1) * M (3, 2) - M (2, 2) * M (3, 1));
   end Determinant;

   function Trace (M : Matrix_3x3) return Real is
   begin
      return M (1, 1) + M (2, 2) + M (3, 3);
   end Trace;

   function Is_Singular (M : Matrix_3x3;
                         Tolerance : Real := Singularity_Threshold) return Boolean is
   begin
      return abs (Determinant (M)) < Tolerance;
   end Is_Singular;

   function Inverse (M : Matrix_3x3) return Matrix_3x3 is
      Det : constant Real := Determinant (M);
      Inv_Det : Real;
      Result : Matrix_3x3;
   begin
      if Is_Singular (M) then
         raise Singularity_Error with "Matrix is singular, cannot invert";
      end if;

      Inv_Det := 1.0 / Det;

      --  Compute adjugate matrix and multiply by 1/det
      Result (1, 1) := Inv_Det * (M (2, 2) * M (3, 3) - M (2, 3) * M (3, 2));
      Result (1, 2) := Inv_Det * (M (1, 3) * M (3, 2) - M (1, 2) * M (3, 3));
      Result (1, 3) := Inv_Det * (M (1, 2) * M (2, 3) - M (1, 3) * M (2, 2));

      Result (2, 1) := Inv_Det * (M (2, 3) * M (3, 1) - M (2, 1) * M (3, 3));
      Result (2, 2) := Inv_Det * (M (1, 1) * M (3, 3) - M (1, 3) * M (3, 1));
      Result (2, 3) := Inv_Det * (M (1, 3) * M (2, 1) - M (1, 1) * M (2, 3));

      Result (3, 1) := Inv_Det * (M (2, 1) * M (3, 2) - M (2, 2) * M (3, 1));
      Result (3, 2) := Inv_Det * (M (1, 2) * M (3, 1) - M (1, 1) * M (3, 2));
      Result (3, 3) := Inv_Det * (M (1, 1) * M (2, 2) - M (1, 2) * M (2, 1));

      return Result;
   end Inverse;

   ---------------------------------------------------------------------------
   -- Rotation Matrices
   ---------------------------------------------------------------------------

   function Rotation_X (Angle : Angle_Radians) return Matrix_3x3 is
      C : constant Real := Cos (Real (Angle));
      S : constant Real := Sin (Real (Angle));
   begin
      return ((1.0, 0.0, 0.0),
              (0.0,   C,  -S),
              (0.0,   S,   C));
   end Rotation_X;

   function Rotation_Y (Angle : Angle_Radians) return Matrix_3x3 is
      C : constant Real := Cos (Real (Angle));
      S : constant Real := Sin (Real (Angle));
   begin
      return ((  C, 0.0,   S),
              (0.0, 1.0, 0.0),
              ( -S, 0.0,   C));
   end Rotation_Y;

   function Rotation_Z (Angle : Angle_Radians) return Matrix_3x3 is
      C : constant Real := Cos (Real (Angle));
      S : constant Real := Sin (Real (Angle));
   begin
      return ((  C,  -S, 0.0),
              (  S,   C, 0.0),
              (0.0, 0.0, 1.0));
   end Rotation_Z;

   function Rotation_Axis_Angle (Axis  : Vector_3D;
                                  Angle : Angle_Radians) return Matrix_3x3 is
      --  Rodrigues' rotation formula in matrix form
      C : constant Real := Cos (Real (Angle));
      S : constant Real := Sin (Real (Angle));
      T : constant Real := 1.0 - C;

      --  Normalize axis
      Mag : constant Real := Sqrt (Axis (1)**2 + Axis (2)**2 + Axis (3)**2);
      X, Y, Z : Real;
   begin
      if Mag < 1.0e-15 then
         raise Physical_Error with "Rotation axis cannot be zero vector";
      end if;

      X := Axis (1) / Mag;
      Y := Axis (2) / Mag;
      Z := Axis (3) / Mag;

      return ((T * X * X + C,     T * X * Y - S * Z, T * X * Z + S * Y),
              (T * X * Y + S * Z, T * Y * Y + C,     T * Y * Z - S * X),
              (T * X * Z - S * Y, T * Y * Z + S * X, T * Z * Z + C));
   end Rotation_Axis_Angle;

   ---------------------------------------------------------------------------
   -- Coordinate Frame Transformations
   ---------------------------------------------------------------------------

   function Perifocal_To_Inertial (RAAN        : Angle_Radians;
                                   Inclination : Angle_Radians;
                                   Arg_Periapsis : Angle_Radians) return Matrix_3x3 is
      --  R = R_z(-RAAN) * R_x(-i) * R_z(-omega)
      --  This transforms from perifocal (PQW) to inertial (IJK) frame
      C_Omega : constant Real := Cos (Real (RAAN));
      S_Omega : constant Real := Sin (Real (RAAN));
      C_i     : constant Real := Cos (Real (Inclination));
      S_i     : constant Real := Sin (Real (Inclination));
      C_w     : constant Real := Cos (Real (Arg_Periapsis));
      S_w     : constant Real := Sin (Real (Arg_Periapsis));
   begin
      return ((C_Omega * C_w - S_Omega * C_i * S_w,
               -C_Omega * S_w - S_Omega * C_i * C_w,
               S_Omega * S_i),

              (S_Omega * C_w + C_Omega * C_i * S_w,
               -S_Omega * S_w + C_Omega * C_i * C_w,
               -C_Omega * S_i),

              (S_i * S_w,
               S_i * C_w,
               C_i));
   end Perifocal_To_Inertial;

   function Inertial_To_Perifocal (RAAN        : Angle_Radians;
                                   Inclination : Angle_Radians;
                                   Arg_Periapsis : Angle_Radians) return Matrix_3x3 is
   begin
      --  Inverse of perifocal to inertial is its transpose (orthogonal matrix)
      return Transpose (Perifocal_To_Inertial (RAAN, Inclination, Arg_Periapsis));
   end Inertial_To_Perifocal;

   ---------------------------------------------------------------------------
   -- 6x6 Matrix Operations
   ---------------------------------------------------------------------------

   function "+" (A, B : Matrix_6x6) return Matrix_6x6 is
      Result : Matrix_6x6;
   begin
      for I in 1 .. 6 loop
         for J in 1 .. 6 loop
            Result (I, J) := A (I, J) + B (I, J);
         end loop;
      end loop;
      return Result;
   end "+";

   function "*" (A, B : Matrix_6x6) return Matrix_6x6 is
      Result : Matrix_6x6 := (others => (others => 0.0));
   begin
      for I in 1 .. 6 loop
         for J in 1 .. 6 loop
            for K in 1 .. 6 loop
               Result (I, J) := Result (I, J) + A (I, K) * B (K, J);
            end loop;
         end loop;
      end loop;
      return Result;
   end "*";

   function Transpose (M : Matrix_6x6) return Matrix_6x6 is
      Result : Matrix_6x6;
   begin
      for I in 1 .. 6 loop
         for J in 1 .. 6 loop
            Result (I, J) := M (J, I);
         end loop;
      end loop;
      return Result;
   end Transpose;

end Hale_Orbital.Matrices;
