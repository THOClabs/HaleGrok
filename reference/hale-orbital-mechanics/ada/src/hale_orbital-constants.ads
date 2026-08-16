-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Physical Constants
-------------------------------------------------------------------------------
-- Physical constants from Hale's "Introduction to Space Flight", Appendix B.
-- All values are in the standard units:
--   - Distance: kilometers (km)
--   - Time: seconds (s)
--   - Mass: kilograms (kg)
--   - Gravitational parameters: km^3/s^2
--
-- Reference: Hale, F.J. (1994). Introduction to Space Flight.
--            Prentice Hall. Appendix B.
--
-- SPARK Status: Pure constants, no computation.
-------------------------------------------------------------------------------

with Hale_Orbital.Types; use Hale_Orbital.Types;

package Hale_Orbital.Constants
   with SPARK_Mode => On
is

   pragma Pure;

   ---------------------------------------------------------------------------
   -- Mathematical Constants
   ---------------------------------------------------------------------------

   Pi      : constant Real := 3.14159_26535_89793_23846;
   Two_Pi  : constant Real := 2.0 * Pi;
   Half_Pi : constant Real := Pi / 2.0;

   --  Angle conversions
   Deg_To_Rad : constant Real := Pi / 180.0;
   Rad_To_Deg : constant Real := 180.0 / Pi;

   ---------------------------------------------------------------------------
   -- Universal Physical Constants
   ---------------------------------------------------------------------------

   --  Universal gravitational constant (m^3/kg/s^2)
   --  Note: For orbital mechanics, we typically use mu = G*M directly
   G_Universal : constant := 6.67430e-11;

   --  Speed of light in vacuum (km/s)
   C_Light : constant Velocity_Km_S := 299_792.458;

   ---------------------------------------------------------------------------
   -- Sun Parameters (Hale Appendix B)
   ---------------------------------------------------------------------------

   --  Sun gravitational parameter (km^3/s^2)
   Mu_Sun : constant Gravitational_Parameter := 1.32712440018e11;

   --  Sun radius (km)
   R_Sun : constant Distance_Km := 696_000.0;

   --  Sun mass (kg)
   M_Sun : constant Mass_Kg := 1.9885e30;

   --  Astronomical Unit - mean Earth-Sun distance (km)
   AU : constant Distance_Km := 149_597_870.7;

   ---------------------------------------------------------------------------
   -- Earth Parameters (Hale Appendix B)
   ---------------------------------------------------------------------------

   --  Earth gravitational parameter (km^3/s^2)
   Mu_Earth : constant Gravitational_Parameter := 398_600.4418;

   --  Earth equatorial radius (km)
   R_Earth : constant Distance_Km := 6_378.137;

   --  Earth polar radius (km)
   R_Earth_Polar : constant Distance_Km := 6_356.752;

   --  Earth mass (kg)
   M_Earth : constant Mass_Kg := 5.9724e24;

   --  Earth J2 perturbation coefficient (dimensionless)
   J2_Earth : constant Real := 1.08263e-3;

   --  Earth rotation rate (rad/s)
   Omega_Earth : constant Real := 7.2921150e-5;

   --  Earth sidereal day (seconds)
   Sidereal_Day_Earth : constant Time_Seconds := 86_164.0905;

   --  Geostationary orbit radius (km)
   R_GEO : constant Distance_Km := 42_164.0;

   ---------------------------------------------------------------------------
   -- Moon Parameters (Hale Appendix B)
   ---------------------------------------------------------------------------

   --  Moon gravitational parameter (km^3/s^2)
   Mu_Moon : constant Gravitational_Parameter := 4_902.8;

   --  Moon radius (km)
   R_Moon : constant Distance_Km := 1_737.4;

   --  Moon mass (kg)
   M_Moon : constant Mass_Kg := 7.346e22;

   --  Moon semi-major axis around Earth (km)
   A_Moon : constant Distance_Km := 384_400.0;

   --  Moon orbital period (seconds)
   T_Moon : constant Time_Seconds := 2_360_591.5;

   ---------------------------------------------------------------------------
   -- Mars Parameters
   ---------------------------------------------------------------------------

   --  Mars gravitational parameter (km^3/s^2)
   Mu_Mars : constant Gravitational_Parameter := 42_828.37;

   --  Mars equatorial radius (km)
   R_Mars : constant Distance_Km := 3_396.2;

   --  Mars mass (kg)
   M_Mars : constant Mass_Kg := 6.4171e23;

   --  Mars semi-major axis around Sun (km)
   A_Mars : constant Distance_Km := 227_939_200.0;

   ---------------------------------------------------------------------------
   -- Venus Parameters
   ---------------------------------------------------------------------------

   --  Venus gravitational parameter (km^3/s^2)
   Mu_Venus : constant Gravitational_Parameter := 324_859.0;

   --  Venus radius (km)
   R_Venus : constant Distance_Km := 6_051.8;

   --  Venus semi-major axis around Sun (km)
   A_Venus : constant Distance_Km := 108_208_000.0;

   ---------------------------------------------------------------------------
   -- Jupiter Parameters
   ---------------------------------------------------------------------------

   --  Jupiter gravitational parameter (km^3/s^2)
   Mu_Jupiter : constant Gravitational_Parameter := 126_686_534.0;

   --  Jupiter equatorial radius (km)
   R_Jupiter : constant Distance_Km := 71_492.0;

   --  Jupiter semi-major axis around Sun (km)
   A_Jupiter : constant Distance_Km := 778_570_000.0;

   ---------------------------------------------------------------------------
   -- Standard Orbits (Reference Values)
   ---------------------------------------------------------------------------

   --  Low Earth Orbit altitude range (km)
   LEO_Min_Altitude : constant Distance_Km := 160.0;
   LEO_Max_Altitude : constant Distance_Km := 2_000.0;

   --  International Space Station nominal altitude (km)
   ISS_Altitude : constant Distance_Km := 420.0;

   --  GPS satellite orbit radius (km)
   R_GPS : constant Distance_Km := 26_560.0;

   ---------------------------------------------------------------------------
   -- Three-Body Constants (CR3BP)
   ---------------------------------------------------------------------------

   --  Earth-Moon mass ratio (mu = M_Moon / (M_Earth + M_Moon))
   Mu_Earth_Moon : constant Real := 0.01215058560962404;

   --  Sun-Earth mass ratio
   Mu_Sun_Earth : constant Real := 3.00273e-6;

   --  Sun-Jupiter mass ratio
   Mu_Sun_Jupiter : constant Real := 9.537e-4;

   --  Routh's critical mass ratio for L4/L5 stability
   Mu_Routh_Critical : constant Real := 0.0385208965;

end Hale_Orbital.Constants;
