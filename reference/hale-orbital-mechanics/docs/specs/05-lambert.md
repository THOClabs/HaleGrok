# Spec 05 — Lambert's Problem

Source chapter: Hale Ch. 5. Reference algorithm: Battin (1999), §6.3 (currently implemented); Izzo (2014) universal vercosine planned for Phase 6 replacement.

## Problem statement

Given two position vectors `R1`, `R2` (in a common inertial frame), a time-of-flight `Tof > 0`, and a gravitational parameter `μ > 0`, find the conic orbit connecting `R1` to `R2` in time `Tof`.

## Public API (Ada)

```ada
type Lambert_Result is record
   V1, V2     : Velocity_Vector;
   A          : Distance_Km;
   E          : Real;
   Iterations : Natural;
   Converged  : Boolean;
end record;

function Solve_Lambert (R1, R2 : Position_Vector;
                        Tof    : Time_Seconds;
                        Mu     : Gravitational_Parameter;
                        Long_Way  : Boolean := False;
                        Tolerance : Real := Default_Tolerance) return Lambert_Result;

function Solve_Lambert_Multi (R1, R2  : Position_Vector;
                              Tof     : Time_Seconds;
                              Mu      : Gravitational_Parameter;
                              Max_Revs: Natural := 0;
                              Long_Way: Boolean := False) return Lambert_Solution_Array;
```

Locations:
- Spec: `ada/src/hale_orbital-lambert.ads`
- Body: `ada/src/hale_orbital-lambert.adb` (Battin's method; will be replaced with Izzo's universal vercosine in Phase 6).

## Pre-conditions

- `|R1| > 0`, `|R2| > 0`, `Tof > 0`, `μ > 0`.
- `R1` and `R2` are non-parallel except for the explicit 180°-transfer degenerate case, which is rejected with `Invalid_Orbit`.

## Post-conditions (informal)

- `Converged ⇒ |Propagate(R1, V1, Tof) − R2| < 1e-6 · |R2|`.
- `Departure_Delta_V` and `Arrival_Delta_V` are consistent with the returned `V1`, `V2`.

## Multi-revolution

For `Max_Revs > 0`, the solver enumerates the `0..Max_Revs` revolution branches and returns all converged solutions. Two solutions exist per non-zero revolution count (low-energy and high-energy); both are returned.

## Edge cases

| Case | Behaviour |
|------|-----------|
| `Tof` ≪ minimum-energy ToF | Hyperbolic transfer; convergence may be slow but solution exists |
| `Tof` ≈ Hohmann time | Near-degenerate; convergence still robust |
| Transfer angle ≈ 180° | Out-of-plane component undefined; raises `Invalid_Orbit` |
| `R1` ≈ `R2` | Trivial; `Solution_Exists` returns False |

## Validation oracles

| Source | Test |
|--------|------|
| Vallado Ex. 5-1 | LEO-GEO, `R1 = 6678`, `R2 = 42164`, `Tof = 5.3 h` → `|V1| ≈ 10.15 km/s` |
| Vallado Ex. 5-2 | Earth–Mars, `R1 = 1 AU`, `R2 = 1.524 AU`, `Tof = 200 d` → `|V1| ≈ 32.7 km/s` |
| poliastro multi-rev tests | Multiple-revolution branch correctness |

## Phase 6 upgrade plan

Replace Battin body with **Izzo's universal vercosine formulation** (1.7–2.5× faster than Gooding per the 2024 MDPI study, typical convergence in ≤ 3 iterations). Add Gooding's method as a fallback entry point. Add second-order sensitivities per Russell (JGCD 2022) for use in OD and trajectory optimisation.
