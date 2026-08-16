# DEC-007: Algorithm Selection Rationale

## Design Decision Record

**ID:** DEC-007
**Title:** Algorithm Selection Rationale
**Status:** Approved
**Date:** 2026-01-06
**Author:** HALE Development Team

---

## 1. Context

The library implements core orbital mechanics algorithms. Selection criteria include:
- Numerical stability
- Convergence reliability
- Performance
- Certification traceability (published, validated)

## 2. Algorithm Decisions

### 2.1 Kepler Equation: Newton-Raphson

**Selection:** Newton-Raphson iteration with Laguerre fallback

```ada
-- Newton-Raphson update
E_New := E_Old - F / F_Prime;
-- where F = E - e*sin(E) - M
-- and F_Prime = 1 - e*cos(E)
```

**Rationale:**
- Quadratic convergence for well-conditioned problems
- Well-documented in Vallado, Battin
- Simple derivative computation
- Typical convergence: 3-5 iterations

**Alternatives Considered:**
| Method | Convergence | Rejected Because |
|--------|-------------|------------------|
| Bisection | Linear | Too slow (20+ iterations) |
| Halley | Cubic | More complex, marginal improvement |
| Series expansion | O(e^n) | Poor for high eccentricity |
| Gooding | Optimal | More complex implementation |

**Fallback for High Eccentricity (e > 0.8):**
- Laguerre's method for improved convergence
- Documented in Battin Section 4.4

### 2.2 Universal Variables: Stumpff Functions

**Selection:** Stumpff C(z) and S(z) functions

```ada
function C (Z : Real) return Real;  -- (1 - cos(sqrt(z))) / z
function S (Z : Real) return Real;  -- (sqrt(z) - sin(sqrt(z))) / sqrt(z)^3
```

**Rationale:**
- Unified treatment of elliptic/parabolic/hyperbolic
- No orbit-type branching in propagator
- Numerically stable via Taylor series near z=0
- Documented in Battin Chapter 4

**Alternatives Considered:**
| Method | Rejected Because |
|--------|------------------|
| Separate formulas | Code duplication, type switching |
| Continued fractions | Less common, harder to verify |

**Implementation Notes:**
- Taylor series for |z| < 0.1 (avoids 0/0)
- Direct formula otherwise
- Guaranteed C(z) > 0, S(z) > 0

### 2.3 Lambert Problem: Universal Variables with Bisection

**Selection:** Battin's universal variable formulation

```ada
-- Find z such that:
-- sqrt(mu) * (t - t0) = Chi^3 * S(z) + A * sqrt(Y(z))
```

**Rationale:**
- Handles all transfer types (Type I, II)
- Robust bisection for initial bracket
- Newton refinement for convergence
- Well-documented in Battin, Curtis

**Alternatives Considered:**
| Method | Rejected Because |
|--------|------------------|
| p-iteration | Less robust for edge cases |
| Gooding | More complex, marginal benefit |
| Lancaster-Blanchard | Similar complexity |

**Multi-revolution:**
- Separate N>0 handling
- Initial guess from geometry

### 2.4 State Propagation: Runge-Kutta Family

**Selection:** RK4 (fixed step) and RK7(8) Dormand-Prince (adaptive)

**RK4 (Default):**
```
k1 = f(t, y)
k2 = f(t + h/2, y + h*k1/2)
k3 = f(t + h/2, y + h*k2/2)
k4 = f(t + h, y + h*k3)
y_new = y + h*(k1 + 2*k2 + 2*k3 + k4)/6
```

**Rationale:**
- Classical, well-understood
- Good accuracy for orbital problems
- Simple implementation
- SPARK-provable (no recursion)

**RK7(8) Dormand-Prince (Adaptive):**
- 7th order with 8th order error estimate
- Automatic step size control
- Better for long propagations

**Alternatives Considered:**
| Method | Rejected Because |
|--------|------------------|
| Euler | Too inaccurate |
| RK2/Midpoint | Insufficient accuracy |
| Adams-Bashforth | Requires startup, more state |
| Symplectic | Would add for long-term |

### 2.5 Periodic Orbit Search: Differential Correction

**Selection:** Single-shooting differential correction

```ada
-- Adjust initial conditions to satisfy periodicity
-- X(T/2) = X(0) + dX, where dX → 0
```

**Rationale:**
- Standard for Lyapunov/Halo orbits
- Uses State Transition Matrix
- Well-documented (Howell, Koon et al.)

**Alternatives Considered:**
| Method | Rejected Because |
|--------|------------------|
| Multiple shooting | More complex, similar results |
| Continuation from analytic | Richardson approximation used as guess |
| Genetic algorithm | Overkill, not deterministic |

### 2.6 Coordinate Transformations: Direct Formulas

**Selection:** Direct spherical trigonometry formulas

**Rationale:**
- Avoid quaternion overhead for simple rotations
- Direct from Hale/Vallado
- SPARK-friendly (no complex types)

## 3. Numerical Stability Considerations

### 3.1 Near-Circular Orbits (e → 0)
- Argument of periapsis undefined
- Solution: Use true longitude (ω + ν)

### 3.2 Near-Equatorial Orbits (i → 0)
- RAAN undefined
- Solution: Use longitude of periapsis (Ω + ω)

### 3.3 Near-Parabolic Orbits (e → 1)
- Period → ∞, SMA → ∞
- Solution: Universal variables, parabolic limit

### 3.4 High Eccentricity (e > 0.9)
- Slow Kepler convergence
- Solution: Laguerre fallback, enhanced initial guess

## 4. References

| Algorithm | Primary Reference |
|-----------|-------------------|
| Kepler Newton | Vallado Section 4.4 |
| Stumpff Functions | Battin Section 4.4 |
| Lambert Universal | Battin Section 7.6 |
| RK4 Integration | Vallado Section 8.6 |
| Differential Correction | Howell (1984) |
| Richardson Halo | Richardson (1980) |

## 5. Compliance

| Requirement | Evidence |
|-------------|----------|
| HLR-KE-001 | Newton-Raphson selection |
| HLR-LB-001 | Universal variable Lambert |
| NFR-PERF-002 | < 50 iterations guaranteed |
| NFR-ACC-001 | 1e-12 tolerance achievable |

---

## Revision History

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-01-06 | Initial version |
