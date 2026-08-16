# Spec 07 — Interplanetary Trajectories (Patched Conics)

Source chapters: Hale Ch. 7–8; Vallado Ch. 12. **Status:** planned — to be implemented as `Hale_Orbital.Optimization.Patched_Conics` in Phase 6, layered on top of the existing `Lambert` and `Maneuvers` packages.

## Scope

Patched-conic interplanetary mission design:

1. Sphere-of-influence (SOI) radii from `μ` ratios:
   `r_SOI = a · (m_planet / m_sun)^(2/5)`.
2. Heliocentric transfer ellipse design via `Lambert.Solve_Lambert` between planetary states.
3. Departure hyperbola: hyperbolic excess velocity `v_∞` from heliocentric transfer; injection ΔV from circular parking orbit; B-plane targeting.
4. Arrival hyperbola: incoming `v_∞`, capture ΔV, periapsis radius, turn angle.
5. Gravity-assist flyby geometry (`Hyper-Galileo`): outgoing `v_∞` magnitude preserved, direction rotated by `2·arcsin(1/(1 + r_p·v_∞²/μ))`.
6. Porkchop generation: sweep departure date × arrival date to produce ΔV contour grid.

## Planned API

```ada
package Hale_Orbital.Optimization.Patched_Conics
   with SPARK_Mode => On
is
   type Departure_Hyperbola is record
      V_Inf_Magnitude : Velocity_Km_S;
      V_Inf_Direction : Vector_3D;          -- unit vector in heliocentric frame
      C3              : Specific_Energy;     -- v_∞² km²/s²
      Injection_DV    : Velocity_Km_S;       -- from circular parking orbit
      Parking_Radius  : Distance_Km;
   end record;

   type Arrival_Hyperbola is record
      V_Inf_Magnitude : Velocity_Km_S;
      V_Inf_Direction : Vector_3D;
      C3              : Specific_Energy;
      Capture_DV      : Velocity_Km_S;
      Periapsis_Radius: Distance_Km;
   end record;

   function Sphere_Of_Influence (A_Planet : Distance_Km;
                                 Mu_Planet, Mu_Sun : Gravitational_Parameter)
      return Distance_Km
   with Pre => A_Planet > 0.0 and Mu_Planet > 0.0 and Mu_Sun > 0.0;

   function Design_Departure (R_Planet, V_Planet      : in     Vector_3D;
                              Heliocentric_V_Departure : in     Velocity_Vector;
                              Parking_Radius           : in     Distance_Km;
                              Mu_Planet                : in     Gravitational_Parameter)
      return Departure_Hyperbola;

   function Design_Arrival   (R_Planet, V_Planet      : in     Vector_3D;
                              Heliocentric_V_Arrival   : in     Velocity_Vector;
                              Periapsis_Radius         : in     Distance_Km;
                              Mu_Planet                : in     Gravitational_Parameter)
      return Arrival_Hyperbola;

   function Gravity_Assist  (V_Inf_In        : Vector_3D;
                             Flyby_Periapsis : Distance_Km;
                             Mu_Planet       : Gravitational_Parameter;
                             B_Plane_Angle   : Angle_Radians)
      return Vector_3D;

   --  Porkchop generator (CSV output; ΔV contour grid)
   procedure Generate_Porkchop (Origin_Body, Destination_Body : String;
                                Departure_JD_Range            : in JD_Range;
                                Arrival_JD_Range              : in JD_Range;
                                N_Departure, N_Arrival        : Positive;
                                CSV_Path                      : String);
end Hale_Orbital.Optimization.Patched_Conics;
```

## Validation oracles

| Mission | TOF | Expected ΔV (departure + arrival) | Source |
|---------|-----|-----------------------------------|--------|
| Earth → Mars Hohmann | 259 d | C3 ≈ 8.6 km²/s²; capture ≈ 2.0 km/s | Vallado §12.4 |
| Earth → Jupiter | ≈ 996 d | C3 ≈ 80 km²/s² | Vallado §12.5 |
| Earth → Venus | ≈ 146 d | C3 ≈ 7.6 km²/s² | Vallado §12.4 |

## Limitations of patched conics

- Single-body gravity at any instant; ignores three-body effects in the SOI handoff regions.
- For low-energy / weak-stability-boundary transfers, prefer the `Threebody.Manifolds` route (Phase 7).
- Light-time, relativistic corrections, and full ephemeris integration are deferred to the high-fidelity force-model propagator chain (`Forces` + `Propagators`).
