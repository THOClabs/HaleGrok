-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Matrix Operations
-------------------------------------------------------------------------------
-- Matrix operations for orbital mechanics calculations including
-- rotation matrices, coordinate transformations, and linear algebra.
--
-- SPARK Status: contracts defined on the spec; body is SPARK_Mode Off
-- (generic instantiation) and has NOT been proven — gnatprove has never run.
-------------------------------------------------------------------------------

with Hale_Orbital.Types; use Hale_Orbital.Types;

package Hale_Orbital.Matrices
   with SPARK_Mode => On
is

   pragma Pure;

   ---------------------------------------------------------------------------
   -- Basic Matrix Arithmetic
   ---------------------------------------------------------------------------

   --  Matrix addition
   function "+" (A, B : Matrix_3x3) return Matrix_3x3
      with Global => null;

   --  Matrix subtraction
   function "-" (A, B : Matrix_3x3) return Matrix_3x3
      with Global => null;

   --  Matrix negation
   function "-" (M : Matrix_3x3) return Matrix_3x3
      with Global => null;

   --  Scalar multiplication
   function "*" (S : Real; M : Matrix_3x3) return Matrix_3x3
      with Global => null;
   function "*" (M : Matrix_3x3; S : Real) return Matrix_3x3
      with Global => null;

   --  Matrix multiplication
   function "*" (A, B : Matrix_3x3) return Matrix_3x3
      with Global => null;

   --  Matrix-vector multiplication
   function "*" (M : Matrix_3x3; V : Vector_3D) return Vector_3D
      with Global => null;

   ---------------------------------------------------------------------------
   -- Matrix Properties
   ---------------------------------------------------------------------------

   --  Matrix transpose
   function Transpose (M : Matrix_3x3) return Matrix_3x3
      with Global => null;

   --  Matrix determinant
   function Determinant (M : Matrix_3x3) return Real
      with Global => null;

   --  Matrix trace (sum of diagonal elements)
   function Trace (M : Matrix_3x3) return Real
      with Global => null;

   --  Shared singularity threshold: Is_Singular and Inverse use the SAME
   --  value, so a matrix reported singular can never be silently inverted
   --  (they previously disagreed by three orders of magnitude, 1.0e-12 vs
   --  1.0e-15 — see DEC-009 numerical-thresholds rationale).
   Singularity_Threshold : constant Real := 1.0e-12;

   --  Matrix inverse (raises Singularity_Error if Is_Singular)
   function Inverse (M : Matrix_3x3) return Matrix_3x3
      with Global => null;

   --  Check if matrix is singular
   function Is_Singular (M : Matrix_3x3;
                         Tolerance : Real := Singularity_Threshold) return Boolean
      with Global => null;

   ---------------------------------------------------------------------------
   -- Rotation Matrices
   ---------------------------------------------------------------------------

   --  Rotation matrix around X-axis (roll)
   function Rotation_X (Angle : Angle_Radians) return Matrix_3x3
      with Global => null;

   --  Rotation matrix around Y-axis (pitch)
   function Rotation_Y (Angle : Angle_Radians) return Matrix_3x3
      with Global => null;

   --  Rotation matrix around Z-axis (yaw)
   function Rotation_Z (Angle : Angle_Radians) return Matrix_3x3
      with Global => null;

   --  Rotation matrix for arbitrary axis (Rodrigues' formula)
   --  Axis must be a unit vector
   function Rotation_Axis_Angle (Axis  : Vector_3D;
                                  Angle : Angle_Radians) return Matrix_3x3
      with Global => null;

   ---------------------------------------------------------------------------
   -- Coordinate Frame Transformations
   ---------------------------------------------------------------------------

   --  Perifocal to inertial (ECI) frame transformation
   --  Uses RAAN (Omega), inclination (i), and argument of periapsis (omega)
   function Perifocal_To_Inertial (RAAN        : Angle_Radians;
                                   Inclination : Angle_Radians;
                                   Arg_Periapsis : Angle_Radians) return Matrix_3x3
      with Global => null;

   --  Inertial (ECI) to perifocal frame transformation
   function Inertial_To_Perifocal (RAAN        : Angle_Radians;
                                   Inclination : Angle_Radians;
                                   Arg_Periapsis : Angle_Radians) return Matrix_3x3
      with Global => null;

   ---------------------------------------------------------------------------
   -- 6x6 Matrix Operations (for State Transition Matrix)
   ---------------------------------------------------------------------------

   --  6x6 matrix addition
   function "+" (A, B : Matrix_6x6) return Matrix_6x6
      with Global => null;

   --  6x6 matrix multiplication
   function "*" (A, B : Matrix_6x6) return Matrix_6x6
      with Global => null;

   --  6x6 identity matrix
   Identity_6x6 : constant Matrix_6x6;

   --  6x6 matrix transpose
   function Transpose (M : Matrix_6x6) return Matrix_6x6
      with Global => null;

private

   Identity_6x6 : constant Matrix_6x6 :=
      ((1.0, 0.0, 0.0, 0.0, 0.0, 0.0),
       (0.0, 1.0, 0.0, 0.0, 0.0, 0.0),
       (0.0, 0.0, 1.0, 0.0, 0.0, 0.0),
       (0.0, 0.0, 0.0, 1.0, 0.0, 0.0),
       (0.0, 0.0, 0.0, 0.0, 1.0, 0.0),
       (0.0, 0.0, 0.0, 0.0, 0.0, 1.0));

end Hale_Orbital.Matrices;
