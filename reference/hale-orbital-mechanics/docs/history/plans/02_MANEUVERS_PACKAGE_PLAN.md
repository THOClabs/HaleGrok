# Maneuvers Package Implementation Plan
## Vision 4: The Art of the Burn

*Champions: Robert Dewar (Ada) + Tom Cotton (Hobbit)*

---

## Overview

The maneuvers package calculates orbital transfers: Hohmann, bi-elliptic, plane changes, and more. Every gram of fuel matters; every delta-V must be optimal.

---

## Current State

**Specification**: ✅ Complete (`hale_orbital-maneuvers.ads`)
**Body**: ❌ Needs implementation (`hale_orbital-maneuvers.adb`)

### Existing API (174 lines)

```ada
-- Major functions defined:
function Hohmann_Transfer (...) return Hohmann_Result;
function Bielliptic_Transfer (...) return Bielliptic_Result;
function Simple_Plane_Change (...) return Velocity_Km_S;
function Combined_Plane_Change (...) return Velocity_Km_S;
function Phasing_Orbit_SMA (...) return Distance_Km;
function Escape_Delta_V (...) return Velocity_Km_S;
function Departure_Velocity (...) return Velocity_Km_S;
```

---

## Implementation Details

### Hohmann Transfer

**The Classic Two-Impulse Transfer**

```ada
function Hohmann_Transfer (R_Initial : Distance_Km;
                           R_Final   : Distance_Km;
                           Mu        : Gravitational_Parameter)
   return Hohmann_Result
is
   -- Transfer ellipse semi-major axis
   A_Transfer : constant Distance_Km :=
      Distance_Km ((Real(R_Initial) + Real(R_Final)) / 2.0);

   -- Eccentricity of transfer ellipse
   E_Transfer : constant Real :=
      abs(Real(R_Final) - Real(R_Initial)) /
         (Real(R_Final) + Real(R_Initial));

   -- Velocities in initial circular orbit
   V_Circ_Initial : constant Real := Sqrt(Real(Mu) / Real(R_Initial));

   -- Velocity at periapsis of transfer ellipse
   V_Transfer_Peri : constant Real :=
      Sqrt(Real(Mu) * (2.0/Real(R_Initial) - 1.0/Real(A_Transfer)));

   -- Velocity at apoapsis of transfer ellipse
   V_Transfer_Apo : constant Real :=
      Sqrt(Real(Mu) * (2.0/Real(R_Final) - 1.0/Real(A_Transfer)));

   -- Velocity in final circular orbit
   V_Circ_Final : constant Real := Sqrt(Real(Mu) / Real(R_Final));

   -- Delta-Vs (absolute values)
   DV1 : constant Velocity_Km_S := Velocity_Km_S(abs(V_Transfer_Peri - V_Circ_Initial));
   DV2 : constant Velocity_Km_S := Velocity_Km_S(abs(V_Circ_Final - V_Transfer_Apo));

   -- Transfer time (half period of transfer ellipse)
   T_Transfer : constant Time_Seconds :=
      Time_Seconds(Pi * Sqrt(Real(A_Transfer)**3 / Real(Mu)));

begin
   return (Delta_V1      => DV1,
           Delta_V2      => DV2,
           Total_Delta_V => Velocity_Km_S(Real(DV1) + Real(DV2)),
           Transfer_Time => T_Transfer,
           A_Transfer    => A_Transfer,
           E_Transfer    => E_Transfer);
end Hohmann_Transfer;
```

**Performance** (Tom Cotton):
```ada
-- All intermediate values as constants = computed at compile time where possible
-- Expression functions for simple conversions
-- Inline pragma for the whole function

pragma Inline (Hohmann_Transfer);
```

---

### Bi-Elliptic Transfer

**More Efficient When R_Final/R_Initial > 11.94**

```ada
function Bielliptic_Transfer (R_Initial     : Distance_Km;
                              R_Final       : Distance_Km;
                              R_Intermediate: Distance_Km;
                              Mu            : Gravitational_Parameter)
   return Bielliptic_Result
is
   -- First transfer ellipse: R_Initial to R_Intermediate
   A1 : constant Real := (Real(R_Initial) + Real(R_Intermediate)) / 2.0;

   -- Second transfer ellipse: R_Intermediate to R_Final
   A2 : constant Real := (Real(R_Intermediate) + Real(R_Final)) / 2.0;

   -- Velocities at key points
   V_Circ_Initial : constant Real := Sqrt(Real(Mu) / Real(R_Initial));
   V_Trans1_Peri  : constant Real := Sqrt(Real(Mu) * (2.0/Real(R_Initial) - 1.0/A1));
   V_Trans1_Apo   : constant Real := Sqrt(Real(Mu) * (2.0/Real(R_Intermediate) - 1.0/A1));
   V_Trans2_Apo   : constant Real := Sqrt(Real(Mu) * (2.0/Real(R_Intermediate) - 1.0/A2));
   V_Trans2_Peri  : constant Real := Sqrt(Real(Mu) * (2.0/Real(R_Final) - 1.0/A2));
   V_Circ_Final   : constant Real := Sqrt(Real(Mu) / Real(R_Final));

   -- Three burns
   DV1 : constant Velocity_Km_S := Velocity_Km_S(abs(V_Trans1_Peri - V_Circ_Initial));
   DV2 : constant Velocity_Km_S := Velocity_Km_S(abs(V_Trans2_Apo - V_Trans1_Apo));
   DV3 : constant Velocity_Km_S := Velocity_Km_S(abs(V_Circ_Final - V_Trans2_Peri));

   -- Transfer times
   T1 : constant Real := Pi * Sqrt(A1**3 / Real(Mu));
   T2 : constant Real := Pi * Sqrt(A2**3 / Real(Mu));

begin
   return (Delta_V1       => DV1,
           Delta_V2       => DV2,
           Delta_V3       => DV3,
           Total_Delta_V  => Velocity_Km_S(Real(DV1) + Real(DV2) + Real(DV3)),
           Transfer_Time  => Time_Seconds(T1 + T2),
           R_Intermediate => R_Intermediate);
end Bielliptic_Transfer;
```

---

### Efficiency Comparison

```ada
function Bielliptic_Is_Efficient (R_Initial : Distance_Km;
                                  R_Final   : Distance_Km) return Boolean
is
   Ratio : constant Real := Real(R_Final) / Real(R_Initial);
begin
   -- Bi-elliptic beats Hohmann when ratio > 11.94
   return Ratio > 11.94;
end Bielliptic_Is_Efficient;

function Optimal_Bielliptic_Radius (R_Initial : Distance_Km;
                                    R_Final   : Distance_Km;
                                    Mu        : Gravitational_Parameter)
   return Distance_Km
is
   Ratio : constant Real := Real(R_Final) / Real(R_Initial);
begin
   if Ratio <= 11.94 then
      return Distance_Km(0.0);  -- Hohmann is better
   else
      -- Optimal intermediate radius (infinity gives minimum dV)
      -- Practical limit: use large but finite value
      return Distance_Km(Real(R_Final) * 10.0);
   end if;
end Optimal_Bielliptic_Radius;
```

---

### Plane Change Maneuvers

```ada
-- Simple plane change at constant velocity magnitude
function Simple_Plane_Change (Delta_I : Angle_Radians;
                              V       : Velocity_Km_S) return Velocity_Km_S
is
begin
   -- Delta-V for plane change: 2*V*sin(Delta_I/2)
   return Velocity_Km_S(2.0 * Real(V) * Sin(Real(Delta_I) / 2.0));
end Simple_Plane_Change;

-- Combined altitude and plane change (at transfer apoapsis)
function Combined_Plane_Change (R_Initial : Distance_Km;
                                R_Final   : Distance_Km;
                                Delta_I   : Angle_Radians;
                                Mu        : Gravitational_Parameter)
   return Velocity_Km_S
is
   -- Perform plane change at apoapsis where velocity is lowest
   A_Transfer : constant Real := (Real(R_Initial) + Real(R_Final)) / 2.0;
   V_Apo_Transfer : constant Real :=
      Sqrt(Real(Mu) * (2.0/Real(R_Final) - 1.0/A_Transfer));
   V_Circ_Final : constant Real := Sqrt(Real(Mu) / Real(R_Final));

   -- Vector addition of velocity change
   DV : constant Real := Sqrt(V_Apo_Transfer**2 + V_Circ_Final**2 -
                               2.0 * V_Apo_Transfer * V_Circ_Final *
                               Cos(Real(Delta_I)));
begin
   return Velocity_Km_S(DV);
end Combined_Plane_Change;
```

---

### Phasing Maneuvers

```ada
function Phasing_Orbit_SMA (R_Orbit     : Distance_Km;
                            Phase_Angle : Angle_Radians;
                            N_Orbits    : Positive;
                            Mu          : Gravitational_Parameter)
   return Distance_Km
is
   -- Period of target orbit
   T_Target : constant Real := 2.0 * Pi * Sqrt(Real(R_Orbit)**3 / Real(Mu));

   -- Time to close phase angle (N target orbits)
   T_Phasing : constant Real := Real(N_Orbits) * T_Target *
                                 (1.0 - Real(Phase_Angle) / (2.0 * Pi));

   -- Semi-major axis that gives period T_Phasing for N orbits
   A_Phasing : constant Real := (Real(Mu) * (T_Phasing / (2.0 * Pi * Real(N_Orbits)))**2) ** (1.0/3.0);
begin
   return Distance_Km(A_Phasing);
end Phasing_Orbit_SMA;
```

---

### Escape and Capture

```ada
function Escape_Delta_V (R : Distance_Km;
                         Mu : Gravitational_Parameter) return Velocity_Km_S
is
   V_Circ : constant Real := Sqrt(Real(Mu) / Real(R));
   V_Escape : constant Real := V_Circ * Sqrt(2.0);
begin
   return Velocity_Km_S(V_Escape - V_Circ);
end Escape_Delta_V;

function C3_Energy (V_Infinity : Velocity_Km_S) return Specific_Energy is
begin
   return Specific_Energy(Real(V_Infinity)**2);
end C3_Energy;

function Departure_Velocity (R  : Distance_Km;
                             C3 : Specific_Energy;
                             Mu : Gravitational_Parameter) return Velocity_Km_S
is
begin
   -- V² = C3 + 2μ/r
   return Velocity_Km_S(Sqrt(Real(C3) + 2.0 * Real(Mu) / Real(R)));
end Departure_Velocity;
```

---

## Test Plan

### Validation Data (Sam)

| Maneuver | R1 (km) | R2 (km) | Expected ΔV | Source |
|----------|---------|---------|-------------|--------|
| LEO-GEO Hohmann | 6,678 | 42,164 | 3.935 km/s | Hale 6.2 |
| LEO-Moon | 6,678 | 384,400 | 3.13 km/s | Hale 6.3 |
| GEO plane change 28° | 42,164 | 42,164 | 1.46 km/s | Hale 6.4 |
| LEO escape | 6,678 | ∞ | 3.23 km/s | Calculated |

### Unit Tests

```ada
procedure Test_Hohmann_LEO_to_GEO is
   Result : constant Hohmann_Result :=
      Hohmann_Transfer (R_Initial => 6678.0,
                        R_Final   => 42164.0,
                        Mu        => 398600.4418);
begin
   Assert_Near (Real(Result.Total_Delta_V), 3.935, Tolerance => 0.01);
   Assert_Near (Real(Result.Transfer_Time), 5.256 * 3600.0, Tolerance => 60.0);
end Test_Hohmann_LEO_to_GEO;
```

### Edge Cases (Pippin)

| Case | Test |
|------|------|
| R_Initial = R_Final | Should return zero delta-V |
| R_Final < R_Initial | Should work (descending transfer) |
| Very high ratio (1000x) | Bi-elliptic should be efficient |
| Zero plane change | Should return zero |
| 180° plane change | Should be 2*V |

---

## Performance Targets (Tom)

| Function | Target | Strategy |
|----------|--------|----------|
| Hohmann_Transfer | < 100 ns | Inline, no allocation |
| Bielliptic_Transfer | < 200 ns | Inline |
| Simple_Plane_Change | < 50 ns | Expression function |
| Escape_Delta_V | < 50 ns | Expression function |

**Optimization Pragmas**:
```ada
pragma Inline (Hohmann_Transfer);
pragma Inline (Bielliptic_Transfer);
pragma Inline (Simple_Plane_Change);
pragma Pure (Hale_Orbital.Maneuvers);
```

---

## SPARK Annotations (Ben)

```ada
function Hohmann_Transfer (R_Initial : Distance_Km;
                           R_Final   : Distance_Km;
                           Mu        : Gravitational_Parameter)
   return Hohmann_Result
   with Global => null,
        Pre    => Real(R_Initial) > 0.0
              and Real(R_Final) > 0.0
              and Real(Mu) > 0.0,
        Post   => Real(Hohmann_Transfer'Result.Total_Delta_V) >= 0.0
              and Real(Hohmann_Transfer'Result.Transfer_Time) > 0.0;
```

---

## Deliverables Checklist

- [ ] `hale_orbital-maneuvers.adb` - Full implementation
- [ ] Hohmann_Transfer (all variants)
- [ ] Bielliptic_Transfer
- [ ] Plane change functions
- [ ] Phasing maneuvers
- [ ] Escape/capture functions
- [ ] Unit tests (10+ tests)
- [ ] Reference validation (4+ cases)
- [ ] Performance benchmarks (<100ns Hohmann)
- [ ] SPARK annotations
- [ ] Lobelia's approval

---

*"Every kilogram of fuel saved is a kilogram of payload delivered. Optimize the burns."*

— Tom Cotton, Performance Engineer

