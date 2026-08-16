-------------------------------------------------------------------------------
-- HALE Orbital Mechanics Library
-------------------------------------------------------------------------------
-- Root package specification for the HALE Orbital Mechanics library.
-- Based on Francis J. Hale's "Introduction to Space Flight" (Prentice Hall, 1994)
--
-- This library provides:
--   - Two-body orbital dynamics
--   - Orbital element conversions
--   - Kepler's equation solvers
--   - Lambert problem solver
--   - Orbital maneuver calculations
--   - Interplanetary trajectory design
--   - Three-body dynamics (CR3BP extension)
--
-- All calculations use:
--   - Distance: kilometers (km)
--   - Time: seconds (s)
--   - Angles: radians (internal), degrees (documentation)
--   - Gravitational parameters: km^3/s^2
--
-- Copyright (c) 2026 HALE Orbital Mechanics Project
-- Licensed under MIT License
-------------------------------------------------------------------------------

package Hale_Orbital
   with SPARK_Mode => On
is

   pragma Pure;

   --  Library version
   Version_Major : constant := 0;
   Version_Minor : constant := 1;
   Version_Patch : constant := 0;

   function Version return String
      with Global => null;
   --  Returns version string in format "Major.Minor.Patch"

private
   --  Implementation details hidden from library users

end Hale_Orbital;
