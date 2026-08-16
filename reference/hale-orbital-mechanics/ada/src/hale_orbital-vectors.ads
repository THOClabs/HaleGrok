-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Vector Operations
-------------------------------------------------------------------------------
-- 3D vector operations for orbital mechanics calculations.
-- All operations follow standard right-handed coordinate conventions.
--
-- SPARK Status: contracts defined on the spec; body is SPARK_Mode Off
-- (generic instantiation) and has NOT been proven — gnatprove has never run.
-------------------------------------------------------------------------------

with Hale_Orbital.Types; use Hale_Orbital.Types;

package Hale_Orbital.Vectors
   with SPARK_Mode => On
is

   pragma Pure;

   ---------------------------------------------------------------------------
   -- Basic Vector Arithmetic
   ---------------------------------------------------------------------------

   --  Vector addition
   function "+" (A, B : Vector_3D) return Vector_3D
      with Global => null;

   --  Vector subtraction
   function "-" (A, B : Vector_3D) return Vector_3D
      with Global => null;

   --  Vector negation
   function "-" (V : Vector_3D) return Vector_3D
      with Global => null;

   --  Scalar multiplication (both orderings)
   function "*" (S : Real; V : Vector_3D) return Vector_3D
      with Global => null;
   function "*" (V : Vector_3D; S : Real) return Vector_3D
      with Global => null;

   --  Scalar division
   function "/" (V : Vector_3D; S : Real) return Vector_3D
      with Pre => S /= 0.0,
           Global => null;

   ---------------------------------------------------------------------------
   -- Vector Products
   ---------------------------------------------------------------------------

   --  Dot product (inner product)
   function Dot (A, B : Vector_3D) return Real
      with Global => null;

   --  Cross product (vector product)
   --  Returns A x B using right-hand rule
   function Cross (A, B : Vector_3D) return Vector_3D
      with Global => null;

   ---------------------------------------------------------------------------
   -- Vector Properties
   ---------------------------------------------------------------------------

   --  Euclidean magnitude (L2 norm)
   function Magnitude (V : Vector_3D) return Real
      with Post => Magnitude'Result >= 0.0,
           Global => null;

   --  Squared magnitude (avoids square root)
   function Magnitude_Squared (V : Vector_3D) return Real
      with Post => Magnitude_Squared'Result >= 0.0,
           Global => null;

   --  Unit vector (normalized to magnitude 1)
   --  Precondition: V must not be zero vector
   function Normalize (V : Vector_3D) return Vector_3D
      with Pre  => Magnitude_Squared (V) > 0.0,
           Post => abs (Magnitude (Normalize'Result) - 1.0) < 1.0e-10,
           Global => null;

   --  Check if vector is zero (within tolerance)
   function Is_Zero (V : Vector_3D; Tolerance : Real := 1.0e-12) return Boolean
      with Global => null;

   --  Check if vectors are parallel (within tolerance)
   function Are_Parallel (A, B : Vector_3D; Tolerance : Real := 1.0e-12) return Boolean
      with Global => null;

   --  Check if vectors are perpendicular (within tolerance)
   function Are_Perpendicular (A, B : Vector_3D; Tolerance : Real := 1.0e-12) return Boolean
      with Global => null;

   ---------------------------------------------------------------------------
   -- Angle Operations
   ---------------------------------------------------------------------------

   --  Angle between two vectors (radians, 0 to Pi)
   function Angle_Between (A, B : Vector_3D) return Angle_Radians
      with Pre  => Magnitude_Squared (A) > 0.0 and Magnitude_Squared (B) > 0.0,
           Post => Real (Angle_Between'Result) >= 0.0
                   and Real (Angle_Between'Result) <= 3.14159265358979,
           Global => null;

   --  Project vector A onto vector B
   function Project (A : Vector_3D; Onto_B : Vector_3D) return Vector_3D
      with Pre => Magnitude_Squared (Onto_B) > 0.0,
           Global => null;

   --  Component of A perpendicular to B
   function Perpendicular_Component (A : Vector_3D; To_B : Vector_3D) return Vector_3D
      with Global => null;

   ---------------------------------------------------------------------------
   -- Rotation Operations
   ---------------------------------------------------------------------------

   --  Rotate vector around X-axis by given angle
   function Rotate_X (V : Vector_3D; Angle : Angle_Radians) return Vector_3D
      with Global => null;

   --  Rotate vector around Y-axis by given angle
   function Rotate_Y (V : Vector_3D; Angle : Angle_Radians) return Vector_3D
      with Global => null;

   --  Rotate vector around Z-axis by given angle
   function Rotate_Z (V : Vector_3D; Angle : Angle_Radians) return Vector_3D
      with Global => null;

   --  Rotate vector around arbitrary axis by given angle
   --  Axis must be a unit vector
   function Rotate_About_Axis (V    : Vector_3D;
                                Axis  : Vector_3D;
                                Angle : Angle_Radians) return Vector_3D
      with Global => null;

   ---------------------------------------------------------------------------
   -- Coordinate Transformations
   ---------------------------------------------------------------------------

   --  Convert Cartesian (x, y, z) to spherical (r, theta, phi)
   --  Returns (radius, polar angle from +Z, azimuth from +X in XY plane)
   procedure Cartesian_To_Spherical (V     : in  Vector_3D;
                                     R     : out Real;
                                     Theta : out Angle_Radians;
                                     Phi   : out Angle_Radians)
      with Global => null,
           Depends => ((R, Theta, Phi) => V);

   --  Convert spherical to Cartesian
   function Spherical_To_Cartesian (R     : Real;
                                    Theta : Angle_Radians;
                                    Phi   : Angle_Radians) return Vector_3D
      with Global => null;

   ---------------------------------------------------------------------------
   -- Ghost Functions for SPARK Proofs (ISS-019)
   ---------------------------------------------------------------------------
   --  These Ghost functions express mathematical properties that can be
   --  verified by the SPARK prover without affecting runtime code.

   --  Predicate: vector has non-negative magnitude
   --  Mathematical property: ||v|| >= 0 for all vectors v
   function Is_Valid_Magnitude (V : Vector_3D) return Boolean is
      (Magnitude_Squared (V) >= 0.0)
   with Ghost;

   --  Predicate: vector is a unit vector (within numerical tolerance)
   --  Mathematical property: ||v|| = 1
   function Is_Unit_Vector (V : Vector_3D) return Boolean is
      (abs (Magnitude (V) - 1.0) < 1.0e-10)
   with Ghost;

   --  Predicate: vectors are orthogonal (within tolerance)
   --  Mathematical property: a · b = 0
   function Are_Orthogonal (A, B : Vector_3D) return Boolean is
      (abs (Dot (A, B)) < 1.0e-10)
   with Ghost;

   --  Ghost lemma: Cross product is orthogonal to both inputs
   --  Mathematical property: (a × b) · a = 0 and (a × b) · b = 0
   function Cross_Product_Is_Orthogonal (A, B : Vector_3D) return Boolean is
      (declare C : constant Vector_3D := Cross (A, B);
       begin abs (Dot (C, A)) < 1.0e-9 and abs (Dot (C, B)) < 1.0e-9)
   with Ghost,
        Pre => Magnitude_Squared (A) > 0.0 and Magnitude_Squared (B) > 0.0;

   --  Ghost lemma: Dot product is commutative
   --  Mathematical property: a · b = b · a
   function Dot_Is_Commutative (A, B : Vector_3D) return Boolean is
      (abs (Dot (A, B) - Dot (B, A)) < 1.0e-15)
   with Ghost;

   --  Ghost lemma: Magnitude is preserved under rotation
   --  Mathematical property: ||R(v)|| = ||v||
   function Rotation_Preserves_Magnitude (V : Vector_3D;
                                          Angle : Angle_Radians) return Boolean is
      (abs (Magnitude (Rotate_Z (V, Angle)) - Magnitude (V)) < 1.0e-10)
   with Ghost;

private
   --  Internal helper for safe arctangent
   function Safe_Atan2 (Y, X : Real) return Real
      with Global => null;

end Hale_Orbital.Vectors;
