# DEC-009: Numerical Threshold Justification

## Design Decision Record

**ID:** DEC-009
**Title:** Numerical Threshold Justification
**Status:** Approved
**Date:** 2026-01-06
**Author:** HALE Development Team

---

## 1. Context

The library uses various numerical thresholds for:
- Detecting near-zero denominators
- Classifying orbit types
- Checking convergence
- Comparing floating-point values

DO-178C requires that all numerical constants be justified and traceable. This document provides that justification.

## 2. IEEE 754 Double Precision Background

| Property | Value |
|----------|-------|
| Precision | 64 bits |
| Mantissa | 52 bits (+ 1 implicit) |
| Machine epsilon | 2.22e-16 |
| Min normal | 2.23e-308 |
| Max value | 1.80e+308 |

**Key Insight:** For double precision, relative errors below ~1e-15 are at machine precision limits.

## 3. Threshold Definitions

### 3.1 Division Safety Threshold

**Value:** `1.0e-15`

**Usage:**
```ada
if abs(Denominator) < 1.0e-15 then
   raise Singularity_Error;
end if;
```

**Justification:**
- 1e-15 ≈ 4.5 × machine_epsilon
- Provides margin above machine precision
- Division by values this small causes >1e15 amplification
- Result would have no meaningful precision

**Locations:**
| File | Line | Denominator |
|------|------|-------------|
| twobody.adb | 164 | 1 + e*cos(ν) |
| twobody.adb | 177 | 2/r - v²/μ |
| kepler.adb | 51 | 1 - e*cos(E) |
| elements.adb | 447 | 1 - tanh²(H/2) |
| vectors.adb | 82, 113, 132, 208, 219 | vector magnitudes (Normalize, Angle_Between, projection, spherical conversions) |
| vectors.adb | 193 | atan2 (0,0) guard |
| matrices.adb | 193 | rotation-axis magnitude |
| lambert.adb | (Small_Threshold, types.ads:135) | Stumpff C(Z), 1−Z·C(Z), Lambert g-function |

**Mathematical Analysis:**

For `r = p / (1 + e*cos(ν))`:
- At periapsis (ν=0): denom = 1 + e (well-conditioned)
- At apoapsis (ν=π): denom = 1 - e (problematic for e→1)
- Condition number: κ = |1 / (1 + e*cos(ν))|

For e = 0.999, ν = π: denom = 0.001, κ = 1000 (acceptable)
For e = 0.9999999999, ν = π: denom ≈ 1e-10, κ ≈ 1e10 (marginal)

Threshold at 1e-15 catches cases where κ > 1e15, beyond useful precision.

### 3.2 Orbit Classification Thresholds

**Circular Threshold:** `1.0e-10`

```ada
if Eccentricity < Circular_Threshold then
   -- Treat as circular orbit
end if;
```

**Justification:**
- Eccentricities below 1e-10 are effectively circular
- Argument of periapsis undefined for e < ~1e-10
- Matches precision of input state vectors (~1e-10 relative)

**Parabolic Threshold:** `1.0e-10`

```ada
if abs(Eccentricity - 1.0) < Parabolic_Threshold then
   -- Treat as parabolic
end if;
```

**Justification:**
- |e - 1| < 1e-10 means semi-major axis > 1e10 × orbit size
- Period → ∞ for practical purposes
- Numerical distinction meaningless beyond this

### 3.3 Convergence Tolerance

**Default Tolerance:** `1.0e-12`

```ada
Default_Tolerance : constant Real := 1.0e-12;
```

**Justification:**
- 1e-12 ≈ 4500 × machine_epsilon
- Allows 3-4 decimal digits of margin
- Achievable in 5-10 Newton iterations
- Matches published Vallado tolerances

**Analysis:**

Newton-Raphson convergence for Kepler equation:
- Residual |E - e*sin(E) - M| after iteration
- Quadratic convergence: εₙ₊₁ ≈ C × εₙ²
- From ε₀ ≈ 1 to ε = 1e-12 requires ~6 iterations

### 3.4 Maximum Iterations

**Value:** `50`

```ada
Default_Max_Iterations : constant Positive := 50;
```

**Justification:**
- Newton-Raphson: typically 5-10 iterations
- Bisection: 50 iterations gives 2⁵⁰ ≈ 1e15 reduction
- Covers worst-case high eccentricity
- Provides termination guarantee

**Mathematical Bound:**

For bisection on interval [a, b]:
- After n iterations: interval width = (b-a)/2ⁿ
- For [−4π², 4π²] and tolerance 1e-12:
- Need n > log₂(8π²/1e-12) ≈ 53 iterations worst case
- 50 iterations adequate for practical cases

### 3.5 Atan2 Safety Threshold

**Value:** `1.0e-15`

```ada
function Safe_Atan2 (Y, X : Real) return Real is
begin
   if abs(X) < 1.0e-15 and abs(Y) < 1.0e-15 then
      return 0.0;  -- Undefined, return conventional value
   end if;
   return Arctan(Y, X);
end Safe_Atan2;
```

**Justification:**
- atan2(0, 0) is mathematically undefined
- Both arguments near machine precision = no useful direction
- Return 0.0 as conventional value (along +x axis)

### 3.6 Lambert Z-Parameter Bounds

**Values:** `Z_Low = -4π²`, `Z_High = 4π²`

**Justification:**
- z < 0: hyperbolic transfer
- z > 0: elliptic transfer
- z = 0: parabolic transfer
- Bounds at ±4π² cover all practical orbital transfers
- Beyond these, transfer is multi-period or degenerate

**Mathematical Basis:**

For universal variable z:
- z = α × χ² where α = 1/a (semi-major axis reciprocal)
- Elliptic: z ∈ (0, 4π²) for 0 < transfer < 1 period
- Hyperbolic: z ∈ (-∞, 0)
- Multi-rev: z > 4π² for N > 0 revolutions

### 3.7 Floating-Point Comparison Tolerance

**Default:** `1.0e-10` for general comparisons

```ada
function Approx_Equal (A, B : Real; Tol : Real := 1.0e-10) return Boolean is
   (abs(A - B) <= Tol * Real'Max(abs(A), abs(B)) + Tol);
```

**Justification:**
- Relative comparison with absolute floor
- 1e-10 relative: 10 decimal digits agreement
- Absolute Tol prevents division by zero when A, B ≈ 0
- Suitable for most orbital mechanics quantities

## 4. Threshold Summary Table

| Threshold | Value | Purpose | Rationale |
|-----------|-------|---------|-----------|
| Division safety | 1.0e-15 | Prevent catastrophic cancellation | ~5× machine epsilon |
| Circular orbit | 1.0e-10 | Orbit classification | Input precision limit |
| Parabolic orbit | 1.0e-10 | Orbit classification | SMA→∞ threshold |
| Convergence | 1.0e-12 | Solver termination | ~5000× machine epsilon |
| Max iterations | 50 | Guaranteed termination | Bisection bound |
| Atan2 safety | 1.0e-15 | Handle (0,0) input | Direction undefined |
| Z bounds | ±4π² | Lambert bracket | Physical transfer limit |
| FP comparison | 1.0e-10 | Relative equality | 10-digit precision |
| Matrix singularity | 1.0e-12 | Is_Singular AND Inverse (shared `Singularity_Threshold`, matrices.ads) | Unified 2026-07-13: the two previously disagreed (1.0e-12 vs 1.0e-15), so a matrix reported singular could still be inverted; fail-closed at the stricter check |
| Lambert denominator guards | 1.0e-15 (`Small_Threshold`) | C(Z), √C(Z), 1−Z·C(Z), g-function guards; violation ⇒ `Converged = False` | IEEE float division never traps on GNAT targets (no `-gnateF` in any mode); guards must be explicit comparisons |
| Stumpff series switch | 1.0e-2 (`Taylor_Threshold`, stumpff.adb) | Use Taylor series for C(z)/S(z) below this \|z\| | Raised 2026-07-13 from 1.0e-10: the closed trig/hyperbolic forms cancel catastrophically for small \|z\| (~1e-8 rel error at z=1e-8, microsecond TOF noise near parabolic boundaries); 5-term series is exact to ~1e-19 at the new threshold; residual closed-form cancellation just outside the seam measured at ~4e-14 rel (C) / ~4e-13 rel (S) |

## 5. Sensitivity Analysis

### 5.1 Division Threshold Sensitivity

| Threshold | Risk if Too Small | Risk if Too Large |
|-----------|-------------------|-------------------|
| < 1e-16 | Overflow, precision loss | N/A |
| 1e-15 | **Selected** | N/A |
| 1e-14 | Safe | Unnecessary rejections |
| 1e-10 | Very safe | Miss valid edge cases |

**Conclusion:** 1e-15 balances safety with capability.

### 5.2 Convergence Tolerance Sensitivity

| Tolerance | Iterations | Accuracy | Notes |
|-----------|------------|----------|-------|
| 1e-8 | ~4 | 8 digits | Fast but imprecise |
| 1e-10 | ~5 | 10 digits | Good balance |
| 1e-12 | ~6 | 12 digits | **Selected**, high accuracy |
| 1e-14 | ~7 | 14 digits | Near machine limit |
| 1e-16 | May not converge | N/A | Below useful precision |

## 6. Compliance

| Issue ID | Threshold | Status |
|----------|-----------|--------|
| ISS-007 | Division 1.0e-15 | Documented |
| ISS-008 | SMA 1.0e-15 | Documented |
| ISS-009 | F_Prime 1.0e-15 | Documented |
| ISS-010 | C_Z check | Documented |
| ISS-026 | Tanh guard | Documented |

---

## Revision History

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-01-06 | Initial version |
