-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Orbital Maneuvers
-------------------------------------------------------------------------------
-- Orbital maneuver calculations including Hohmann transfers, bi-elliptic
-- transfers, plane changes, and combined maneuvers.
--
-- Reference: Hale, F.J. (1994). Introduction to Space Flight.
--            Prentice Hall. Chapter 6.
-------------------------------------------------------------------------------

with Hale_Orbital.Types; use Hale_Orbital.Types;

--  Note: Maneuvers cannot be Pure because the body depends on Twobody,
--  which uses non-pure numeric functions.  The pragma Inline declarations
--  in the private section provide the same call-site inlining benefit.
package Hale_Orbital.Maneuvers
   with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Maneuver Result Type
   ---------------------------------------------------------------------------

   type Hohmann_Result is record
      Delta_V1       : Velocity_Km_S;   -- First burn (departure)
      Delta_V2       : Velocity_Km_S;   -- Second burn (arrival)
      Total_Delta_V  : Velocity_Km_S;   -- Total delta-V
      Transfer_Time  : Time_Seconds;    -- Half-period of transfer ellipse
      A_Transfer     : Distance_Km;     -- Semi-major axis of transfer
      E_Transfer     : Real;            -- Eccentricity of transfer
   end record;

   type Bielliptic_Result is record
      Delta_V1       : Velocity_Km_S;   -- First burn
      Delta_V2       : Velocity_Km_S;   -- Second burn (at apoapsis)
      Delta_V3       : Velocity_Km_S;   -- Third burn (circularize)
      Total_Delta_V  : Velocity_Km_S;   -- Total delta-V
      Transfer_Time  : Time_Seconds;    -- Total transfer time
      R_Intermediate : Distance_Km;     -- Intermediate apoapsis radius
   end record;

   type Plane_Change_Result is record
      Delta_V        : Velocity_Km_S;   -- Required delta-V
      Burn_Location  : Angle_Radians;   -- Optimal location for burn (true anomaly)
   end record;

   ---------------------------------------------------------------------------
   -- Hohmann Transfer (Hale Section 6.2)
   ---------------------------------------------------------------------------

   --  Compute Hohmann transfer between two circular orbits
   --  R_Initial: Initial circular orbit radius (km)
   --  R_Final: Final circular orbit radius (km)
   --  Mu: Gravitational parameter
   function Hohmann_Transfer (R_Initial : Distance_Km;
                              R_Final   : Distance_Km;
                              Mu        : Gravitational_Parameter) return Hohmann_Result
      with Global => null;

   --  Compute delta-V for first Hohmann burn
   function Hohmann_Delta_V1 (R_Initial : Distance_Km;
                              R_Final   : Distance_Km;
                              Mu        : Gravitational_Parameter) return Velocity_Km_S
      with Global => null;

   --  Compute delta-V for second Hohmann burn
   function Hohmann_Delta_V2 (R_Initial : Distance_Km;
                              R_Final   : Distance_Km;
                              Mu        : Gravitational_Parameter) return Velocity_Km_S
      with Global => null;

   --  Compute total delta-V for Hohmann transfer
   function Hohmann_Total_Delta_V (R_Initial : Distance_Km;
                                   R_Final   : Distance_Km;
                                   Mu        : Gravitational_Parameter) return Velocity_Km_S
      with Global => null;

   --  Compute Hohmann transfer time
   function Hohmann_Transfer_Time (R_Initial : Distance_Km;
                                   R_Final   : Distance_Km;
                                   Mu        : Gravitational_Parameter) return Time_Seconds
      with Global => null;

   ---------------------------------------------------------------------------
   -- Bi-Elliptic Transfer (Hale Section 6.3)
   ---------------------------------------------------------------------------

   --  Compute bi-elliptic transfer with specified intermediate radius
   --  More efficient than Hohmann when R_Final/R_Initial > 11.94
   function Bielliptic_Transfer (R_Initial     : Distance_Km;
                                 R_Final       : Distance_Km;
                                 R_Intermediate: Distance_Km;
                                 Mu            : Gravitational_Parameter) return Bielliptic_Result
      with Global => null;

   --  Compute optimal intermediate radius for bi-elliptic transfer
   --  Returns the radius that minimizes total delta-V
   --  Returns 0 if Hohmann is more efficient
   function Optimal_Bielliptic_Radius (R_Initial : Distance_Km;
                                       R_Final   : Distance_Km;
                                       Mu        : Gravitational_Parameter) return Distance_Km
      with Global => null;

   --  Determine if bi-elliptic is more efficient than Hohmann
   --  True when R_Final/R_Initial > 11.94
   function Bielliptic_Is_Efficient (R_Initial : Distance_Km;
                                     R_Final   : Distance_Km) return Boolean
      with Global => null;

   ---------------------------------------------------------------------------
   -- Plane Change Maneuvers (Hale Section 6.4)
   ---------------------------------------------------------------------------

   --  Simple plane change at constant velocity
   --  Delta_I: Change in inclination (radians)
   --  V: Orbital velocity at maneuver point
   function Simple_Plane_Change (Delta_I : Angle_Radians;
                                 V       : Velocity_Km_S) return Velocity_Km_S
      with Global => null;

   --  Optimal combined plane change (at apoapsis of transfer ellipse)
   --  Returns delta-V for combined altitude and plane change
   function Combined_Plane_Change (R_Initial : Distance_Km;
                                   R_Final   : Distance_Km;
                                   Delta_I   : Angle_Radians;
                                   Mu        : Gravitational_Parameter) return Velocity_Km_S
      with Global => null;

   --  Complete combined maneuver (altitude + plane change)
   function Combined_Maneuver (R_Initial : Distance_Km;
                               R_Final   : Distance_Km;
                               Delta_I   : Angle_Radians;
                               Mu        : Gravitational_Parameter) return Hohmann_Result
      with Global => null;

   ---------------------------------------------------------------------------
   -- General Coplanar Transfer
   ---------------------------------------------------------------------------

   --  Transfer between two elliptical orbits (coplanar)
   function Coplanar_Transfer (A1  : Distance_Km;  -- Initial semi-major axis
                               E1  : Real;          -- Initial eccentricity
                               Nu1 : Angle_Radians; -- Initial true anomaly
                               A2  : Distance_Km;  -- Final semi-major axis
                               E2  : Real;          -- Final eccentricity
                               Nu2 : Angle_Radians; -- Final true anomaly
                               Mu  : Gravitational_Parameter) return Transfer_Result
      with Global => null;

   ---------------------------------------------------------------------------
   -- Phasing Maneuvers (Rendezvous)
   ---------------------------------------------------------------------------

   --  Compute phasing orbit for rendezvous
   --  Phase_Angle: Angular separation between chaser and target (radians)
   --  N_Orbits: Number of target orbits to wait
   --  Returns the semi-major axis of the phasing orbit
   function Phasing_Orbit_SMA (R_Orbit     : Distance_Km;
                               Phase_Angle : Angle_Radians;
                               N_Orbits    : Positive;
                               Mu          : Gravitational_Parameter) return Distance_Km
      with Global => null;

   --  Compute total delta-V for phasing maneuver
   function Phasing_Delta_V (R_Orbit     : Distance_Km;
                             Phase_Angle : Angle_Radians;
                             N_Orbits    : Positive;
                             Mu          : Gravitational_Parameter) return Velocity_Km_S
      with Global => null;

   ---------------------------------------------------------------------------
   -- Escape and Capture
   ---------------------------------------------------------------------------

   --  Delta-V to escape from circular orbit
   function Escape_Delta_V (R : Distance_Km;
                            Mu : Gravitational_Parameter) return Velocity_Km_S
      with Global => null;

   --  Delta-V to capture into circular orbit from parabolic approach
   function Capture_Delta_V (R : Distance_Km;
                             Mu : Gravitational_Parameter) return Velocity_Km_S
      with Global => null;

   --  Hyperbolic excess velocity (C3)
   --  V_Infinity: Velocity at infinity
   --  Returns specific energy (km^2/s^2)
   --  Hyperbolic excess velocity (C3)
   --  V_Infinity: Velocity at infinity
   --  Returns specific energy (km^2/s^2)
   function C3_Energy (V_Infinity : Velocity_Km_S)
      return Hale_Orbital.Types.Specific_Energy
      with Global => null;

   --  Velocity required for given C3 at departure radius
   function Departure_Velocity (R  : Distance_Km;
                                C3 : Hale_Orbital.Types.Specific_Energy;
                                Mu : Gravitational_Parameter) return Velocity_Km_S
      with Global => null;

private
   ---------------------------------------------------------------------------
   -- Performance Optimization: Inline Pragmas
   ---------------------------------------------------------------------------
   --  Inline all compute functions for performance (<100 ns target)

   pragma Inline (Hohmann_Transfer);
   pragma Inline (Hohmann_Delta_V1);
   pragma Inline (Hohmann_Delta_V2);
   pragma Inline (Hohmann_Total_Delta_V);
   pragma Inline (Hohmann_Transfer_Time);
   pragma Inline (Bielliptic_Transfer);
   pragma Inline (Bielliptic_Is_Efficient);
   pragma Inline (Simple_Plane_Change);
   pragma Inline (Combined_Plane_Change);
   pragma Inline (Escape_Delta_V);
   pragma Inline (Capture_Delta_V);
   pragma Inline (C3_Energy);
   pragma Inline (Departure_Velocity);
   pragma Inline (Phasing_Delta_V);

end Hale_Orbital.Maneuvers;
