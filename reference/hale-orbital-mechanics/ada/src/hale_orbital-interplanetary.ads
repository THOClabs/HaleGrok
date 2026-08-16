-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Interplanetary Trajectories Package
-------------------------------------------------------------------------------
-- Implements patched conic methodology for interplanetary mission design.
--
-- Features:
--   - Sphere of influence calculations
--   - Patched conic transfers
--   - Gravity assist (flyby) analysis
--   - Planetary departure/arrival hyperbolas
--
-- Reference: Hale "Introduction to Space Flight" Chapters 7-8
--            Vallado "Fundamentals of Astrodynamics" Chapter 12
-------------------------------------------------------------------------------

with Hale_Orbital.Types;    use Hale_Orbital.Types;
with Hale_Orbital.Elements; use Hale_Orbital.Elements;

package Hale_Orbital.Interplanetary
   with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Planetary Data
   ---------------------------------------------------------------------------

   type Planet_Type is (Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune);

   type Planet_Data is record
      Name            : String (1 .. 10);
      Mu              : Gravitational_Parameter;  -- GM (km^3/s^2)
      Semi_Major_Axis : Distance_Km;              -- Heliocentric orbit (km)
      Eccentricity    : Real;                     -- Orbital eccentricity
      Radius          : Distance_Km;              -- Mean radius (km)
      SOI_Radius      : Distance_Km;              -- Sphere of influence (km)
   end record;

   --  Standard planetary data
   function Get_Planet_Data (Planet : Planet_Type) return Planet_Data
      with Global => null;

   --  Sun gravitational parameter
   Mu_Sun : constant Gravitational_Parameter := 132712440018.0;  -- km^3/s^2

   ---------------------------------------------------------------------------
   -- Sphere of Influence
   ---------------------------------------------------------------------------

   --  Calculate sphere of influence radius using Laplace formula
   --  r_SOI = a * (m_planet / m_sun)^(2/5)
   function Sphere_Of_Influence (A_Planet : Distance_Km;
                                  Mu_Planet : Gravitational_Parameter;
                                  Mu_Star   : Gravitational_Parameter := Mu_Sun) return Distance_Km
      with Pre => Real (A_Planet) > 0.0 and
                  Real (Mu_Planet) > 0.0 and
                  Real (Mu_Star) > 0.0,
           Post => Real (Sphere_Of_Influence'Result) > 0.0,
           Global => null;

   --  Check if position is within a planet's sphere of influence
   function Within_SOI (R_From_Planet : Distance_Km;
                        Planet        : Planet_Type) return Boolean
      with Global => null;

   ---------------------------------------------------------------------------
   -- Hyperbolic Trajectory Parameters
   ---------------------------------------------------------------------------

   --  Hyperbolic excess velocity (V_infinity)
   --  V_inf^2 = V^2 - V_esc^2 = V^2 - 2*mu/r
   function Hyperbolic_Excess_Velocity (V_Total  : Velocity_Km_S;
                                        R        : Distance_Km;
                                        Mu       : Gravitational_Parameter) return Velocity_Km_S
      with Pre => Real (V_Total) > 0.0 and
                  Real (R) > 0.0 and
                  Real (Mu) > 0.0,
           Global => null;

   --  Calculate V_infinity from C3 energy
   function V_Infinity_From_C3 (C3 : Hale_Orbital.Types.Specific_Energy) return Velocity_Km_S
      with Pre => Real (C3) >= 0.0,
           Global => null;

   --  Calculate C3 from V_infinity
   function C3_From_V_Infinity (V_Inf : Velocity_Km_S) return Hale_Orbital.Types.Specific_Energy
      with Post => Real (C3_From_V_Infinity'Result) >= 0.0,
           Global => null;

   --  Hyperbolic periapsis velocity given V_infinity and periapsis distance
   function Hyperbolic_Periapsis_Velocity (V_Infinity  : Velocity_Km_S;
                                           R_Periapsis : Distance_Km;
                                           Mu          : Gravitational_Parameter) return Velocity_Km_S
      with Pre => Real (R_Periapsis) > 0.0 and Real (Mu) > 0.0,
           Global => null;

   --  Calculate hyperbolic semi-major axis (negative for hyperbola)
   function Hyperbolic_Semi_Major_Axis (V_Infinity : Velocity_Km_S;
                                        Mu         : Gravitational_Parameter) return Distance_Km
      with Pre => Real (V_Infinity) > 0.0 and Real (Mu) > 0.0,
           Global => null;

   --  Hyperbolic eccentricity given V_infinity and periapsis
   function Hyperbolic_Eccentricity (V_Infinity  : Velocity_Km_S;
                                     R_Periapsis : Distance_Km;
                                     Mu          : Gravitational_Parameter) return Real
      with Pre  => Real (V_Infinity) > 0.0 and
                   Real (R_Periapsis) > 0.0 and
                   Real (Mu) > 0.0,
           Post => Hyperbolic_Eccentricity'Result > 1.0,
           Global => null;

   --  Turn angle (deflection) for a hyperbolic flyby
   function Turn_Angle (V_Infinity  : Velocity_Km_S;
                        R_Periapsis : Distance_Km;
                        Mu          : Gravitational_Parameter) return Angle_Radians
      with Pre => Real (V_Infinity) > 0.0 and
                  Real (R_Periapsis) > 0.0 and
                  Real (Mu) > 0.0,
           Global => null;

   ---------------------------------------------------------------------------
   -- Patched Conic Transfer
   ---------------------------------------------------------------------------

   type Patched_Conic_Result is record
      --  Departure parameters
      Departure_C3       : Hale_Orbital.Types.Specific_Energy;        -- Launch energy requirement
      Departure_V_Inf    : Velocity_Km_S;          -- Departure excess velocity
      Departure_DV       : Velocity_Km_S;          -- Delta-V from parking orbit

      --  Transfer parameters
      Transfer_TOF       : Time_Seconds;           -- Time of flight
      Transfer_SMA       : Distance_Km;            -- Heliocentric semi-major axis
      Transfer_Ecc       : Real;                   -- Heliocentric eccentricity

      --  Arrival parameters
      Arrival_V_Inf      : Velocity_Km_S;          -- Arrival excess velocity
      Arrival_C3         : Hale_Orbital.Types.Specific_Energy;        -- Arrival energy
      Capture_DV         : Velocity_Km_S;          -- Delta-V for orbit insertion

      --  Total mission parameters
      Total_DV           : Velocity_Km_S;          -- Total delta-V (departure + capture)
      Valid              : Boolean;                -- Solution is valid
   end record;

   --  Compute patched conic transfer between two planets
   --  Uses current (simplified) planetary positions
   function Compute_Patched_Conic (Departure_Planet  : Planet_Type;
                                    Arrival_Planet    : Planet_Type;
                                    Time_Of_Flight    : Time_Seconds;
                                    Parking_Altitude  : Distance_Km;
                                    Capture_Altitude  : Distance_Km) return Patched_Conic_Result
      with Pre => Real (Time_Of_Flight) > 0.0 and
                  Real (Parking_Altitude) > 0.0 and
                  Real (Capture_Altitude) > 0.0,
           Global => null;

   --  Estimate Hohmann-like transfer between planetary orbits (simplified)
   function Hohmann_Interplanetary (Departure_Planet : Planet_Type;
                                    Arrival_Planet   : Planet_Type) return Patched_Conic_Result
      with Global => null;

   ---------------------------------------------------------------------------
   -- Gravity Assist (Flyby)
   ---------------------------------------------------------------------------

   type Flyby_Result is record
      Turn_Angle     : Angle_Radians;   -- Deflection angle
      Delta_V_Gain   : Velocity_Km_S;   -- Effective delta-V from flyby
      Exit_V_Inf     : Velocity_Km_S;   -- Exit V_infinity magnitude
      R_Periapsis    : Distance_Km;     -- Closest approach distance
      Valid          : Boolean;         -- Flyby is valid (above surface)
   end record;

   --  Calculate gravity assist parameters
   --  Assumes planar flyby with specified turn angle
   function Compute_Flyby (V_Infinity_In : Velocity_Km_S;
                           R_Periapsis   : Distance_Km;
                           Planet        : Planet_Type) return Flyby_Result
      with Pre => Real (V_Infinity_In) > 0.0 and Real (R_Periapsis) > 0.0,
           Global => null;

   --  Calculate minimum periapsis for given V_infinity and planet
   --  (Just above planetary surface/atmosphere)
   function Minimum_Flyby_Radius (Planet : Planet_Type;
                                   Altitude : Distance_Km := 200.0) return Distance_Km
      with Global => null;

   --  Maximum delta-V available from flyby at given V_infinity
   function Maximum_Flyby_DeltaV (V_Infinity : Velocity_Km_S;
                                   Planet     : Planet_Type) return Velocity_Km_S
      with Pre => Real (V_Infinity) > 0.0,
           Global => null;

   ---------------------------------------------------------------------------
   -- Synodic Period and Launch Windows
   ---------------------------------------------------------------------------

   --  Calculate synodic period between two planets
   function Synodic_Period (Inner_Planet : Planet_Type;
                            Outer_Planet : Planet_Type) return Time_Seconds
      with Pre => Inner_Planet /= Outer_Planet,
           Global => null;

   --  Approximate phase angle for Hohmann transfer
   function Hohmann_Phase_Angle (Departure_Planet : Planet_Type;
                                  Arrival_Planet   : Planet_Type) return Angle_Radians
      with Global => null;

private

   --  Planetary constants (mean values)
   Mercury_Data : constant Planet_Data :=
      (Name            => "Mercury   ",
       Mu              => 22032.0,
       Semi_Major_Axis => 57909050.0,
       Eccentricity    => 0.2056,
       Radius          => 2439.7,
       SOI_Radius      => 112000.0);

   Venus_Data : constant Planet_Data :=
      (Name            => "Venus     ",
       Mu              => 324859.0,
       Semi_Major_Axis => 108208000.0,
       Eccentricity    => 0.0067,
       Radius          => 6051.8,
       SOI_Radius      => 616000.0);

   Earth_Data : constant Planet_Data :=
      (Name            => "Earth     ",
       Mu              => 398600.4418,
       Semi_Major_Axis => 149598023.0,
       Eccentricity    => 0.0167,
       Radius          => 6371.0,
       SOI_Radius      => 925000.0);

   Mars_Data : constant Planet_Data :=
      (Name            => "Mars      ",
       Mu              => 42828.0,
       Semi_Major_Axis => 227939200.0,
       Eccentricity    => 0.0934,
       Radius          => 3389.5,
       SOI_Radius      => 577000.0);

   Jupiter_Data : constant Planet_Data :=
      (Name            => "Jupiter   ",
       Mu              => 126686534.0,
       Semi_Major_Axis => 778570000.0,
       Eccentricity    => 0.0489,
       Radius          => 69911.0,
       SOI_Radius      => 48200000.0);

   Saturn_Data : constant Planet_Data :=
      (Name            => "Saturn    ",
       Mu              => 37931187.0,
       Semi_Major_Axis => 1433530000.0,
       Eccentricity    => 0.0565,
       Radius          => 58232.0,
       SOI_Radius      => 54800000.0);

   Uranus_Data : constant Planet_Data :=
      (Name            => "Uranus    ",
       Mu              => 5793939.0,
       Semi_Major_Axis => 2872460000.0,
       Eccentricity    => 0.0463,
       Radius          => 25362.0,
       SOI_Radius      => 51800000.0);

   Neptune_Data : constant Planet_Data :=
      (Name            => "Neptune   ",
       Mu              => 6836529.0,
       Semi_Major_Axis => 4495060000.0,
       Eccentricity    => 0.0086,
       Radius          => 24622.0,
       SOI_Radius      => 86800000.0);

end Hale_Orbital.Interplanetary;
