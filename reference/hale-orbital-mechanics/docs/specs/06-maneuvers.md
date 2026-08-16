# Spec 06 — Orbital Maneuvers

Source chapter: Hale Ch. 6. Reference values from Hale Tables 6-1 / 6-2 and Vallado Ch. 6.

## Scope

- Hohmann two-impulse transfer between circular orbits.
- Bi-elliptic three-impulse transfer (more efficient for `R2/R1 > 11.94`).
- Simple plane change and altitude-combined plane change.
- General coplanar transfer between elliptical orbits.
- Phasing maneuver for rendezvous.
- Escape (`v∞` from circular orbit) and capture from parabolic approach.
- Hyperbolic excess energy (`C3 = v_∞²`).

## Public API (Ada, condensed)

```ada
function Hohmann_Transfer        (R1, R2 : Distance_Km; Mu : Gravitational_Parameter) return Hohmann_Result;
function Hohmann_Total_Delta_V   (R1, R2 : Distance_Km; Mu : Gravitational_Parameter) return Velocity_Km_S;
function Hohmann_Transfer_Time   (R1, R2 : Distance_Km; Mu : Gravitational_Parameter) return Time_Seconds;

function Bielliptic_Transfer     (R1, R2, R_Inter : Distance_Km; Mu : Gravitational_Parameter) return Bielliptic_Result;
function Optimal_Bielliptic_Radius (R1, R2 : Distance_Km; Mu : Gravitational_Parameter) return Distance_Km;
function Bielliptic_Is_Efficient (R1, R2 : Distance_Km) return Boolean;  -- True ⇔ R2/R1 > 11.94

function Simple_Plane_Change     (Delta_I : Angle_Radians; V : Velocity_Km_S) return Velocity_Km_S;
function Combined_Plane_Change   (R1, R2 : Distance_Km; Delta_I : Angle_Radians;
                                  Mu : Gravitational_Parameter) return Velocity_Km_S;

function Coplanar_Transfer       (A1, E1, Nu1, A2, E2, Nu2 : …; Mu : …) return Transfer_Result;

function Phasing_Orbit_SMA       (R, Phase, N : …; Mu : …) return Distance_Km;
function Phasing_Delta_V         (R, Phase, N : …; Mu : …) return Velocity_Km_S;

function Escape_Delta_V          (R : Distance_Km; Mu : Gravitational_Parameter) return Velocity_Km_S;
function Capture_Delta_V         (R : Distance_Km; Mu : Gravitational_Parameter) return Velocity_Km_S;
function C3_Energy               (V_Inf : Velocity_Km_S) return Specific_Energy;
function Departure_Velocity      (R : Distance_Km; C3 : Specific_Energy;
                                  Mu : Gravitational_Parameter) return Velocity_Km_S;
```

Locations:
- Spec: `ada/src/hale_orbital-maneuvers.ads`
- Body: `ada/src/hale_orbital-maneuvers.adb`

## Pre-conditions

- All radii > 0; `μ > 0`; `N_Orbits ≥ 1` for phasing.
- `Combined_Plane_Change`: `R1, R2 > 0`, `|Δi| ≤ π`.

## Validation oracles

| Transfer | R1 | R2 | Expected ΔV | Source |
|----------|----|----|-------------|--------|
| Hohmann LEO→GEO | 6678 km | 42164 km | 3.935 km/s | Hale Table 6-1 |
| Hohmann LEO→Moon | 6678 km | 384400 km | 3.13 km/s | Hale Table 6-2 |
| Bi-elliptic LEO→far | 6678 km | > 80000 km | < Hohmann | Vallado §6.4 |
| Simple plane change LEO 28° → 0° | — | — | 3.79 km/s | Vallado §6.5 |

## Phase 6 extensions (planned)

- Finite-burn approximations (constant-thrust segments) replacing impulsive assumption.
- Multi-impulse general transfers (3+ burns) — Edelbaum spiraling for low-thrust.
- Gravity-assist geometry (`Hyper-Galileo` flyby; outgoing `v_∞` from incoming `v_∞` and turn angle).
