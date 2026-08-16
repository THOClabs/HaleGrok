# DEC-005: Three-Body Package Structure

**Decision:** Use a single combined `Hale_Orbital.Threebody` package instead of five separate subpackages.

**Status:** Accepted
**Date:** 2026-01-05

---

## Context

The original specification (CONVERSION_PLAN.md Phase 9) proposed organizing the three-body dynamics functionality into five separate subpackages:

1. `Hale_Orbital.Threebody.CR3BP` - Core equations of motion
2. `Hale_Orbital.Threebody.Lagrange` - Lagrange point computation
3. `Hale_Orbital.Threebody.Integrators` - Specialized CR3BP integrators
4. `Hale_Orbital.Threebody.Periodic` - Periodic orbit search
5. `Hale_Orbital.Threebody.Stability` - Stability analysis

The implementation uses a single combined package: `Hale_Orbital.Threebody` (~1,300 lines as of 2026-07; originally ~686 — the periodic-orbit, STM/monodromy, Floquet, and family-continuation machinery has since landed in this same package).

---

## Decision Rationale

### 1. Cohesion Over Granularity

The three-body dynamics functions are highly interdependent:

```
CR3BP Equations  ──▶  Jacobi Constant  ──▶  Zero-Velocity Surfaces
       │                    │                       │
       ▼                    ▼                       ▼
  Propagation  ◀────▶  Stability  ◀────────▶  Lagrange Points
```

Splitting these into separate packages would create circular dependency chains or require artificial dependency breaking.

### 2. Size Does Not Warrant Splitting

At ~1,300 lines the package now EXCEEDS the sizing rationale below (kept for history); the split described in Alternative 2 is the standing recommendation once the module stabilizes:

| Metric | Value | Guideline |
|--------|-------|-----------|
| Lines of code | ~1,300 (was 686) | < 1000 recommended — now exceeded |
| Public subprograms | 24 | < 50 reasonable |
| Types defined | 8 | < 15 reasonable |

Compare with successful Ada packages:
- `Ada.Containers.Vectors`: ~2000 lines
- `Ada.Numerics.Generic_Elementary_Functions`: ~800 lines

### 3. User Convenience

A single `with` statement provides all CR3BP functionality:

```ada
--  Single import for all three-body features
with Hale_Orbital.Threebody; use Hale_Orbital.Threebody;

procedure Mission_Analysis is
   System : constant Threebody_System := Earth_Moon_System;
   L1_Loc : constant Lagrange_Result := Compute_Lagrange_Point (System, L1);
   Stab   : constant Stability_Result := Analyze_Stability (System, L1);
begin
   --  All functionality immediately available
end Mission_Analysis;
```

With subpackages:

```ada
--  Multiple imports for same functionality
with Hale_Orbital.Threebody.CR3BP;
with Hale_Orbital.Threebody.Lagrange;
with Hale_Orbital.Threebody.Stability;
use  Hale_Orbital.Threebody.CR3BP;
use  Hale_Orbital.Threebody.Lagrange;
use  Hale_Orbital.Threebody.Stability;
```

### 4. SPARK Verification Simplification

A single package with `SPARK_Mode => On` simplifies proof obligations:
- All Ghost functions in one scope
- Inter-function dependencies resolved within package
- Single proof context for conservation law verification

### 5. Deferred Features

The "Periodic" and "Integrators" subpackages were specified for:
- Periodic orbit search (monodromy matrix, Floquet analysis)
- Specialized CR3BP integrators (variable step, event detection)

These advanced features are not yet implemented (see ISS-034). When implemented, they may justify splitting if:
- Implementation exceeds 500 additional lines
- Clear interface boundary emerges
- Independent testing is beneficial

---

## Package Organization

The single package is organized into logical sections:

```
Hale_Orbital.Threebody
│
├── System Definition (lines 20-50)
│   └── Threebody_System, Normalized_State types
│
├── Predefined Systems (lines 45-50)
│   └── Earth_Moon, Sun_Earth, Sun_Jupiter constants
│
├── Lagrange Points (lines 55-95)
│   └── Compute_Lagrange_Point, Compute_All_Lagrange_Points
│
├── CR3BP Equations (lines 100-180)
│   └── Pseudo_Potential, Compute_Acceleration, Jacobi_Constant
│
├── Stability Analysis (lines 185-280)
│   └── Analyze_Stability, Stability_Result, eigenvalue analysis
│
├── Propagation (lines 285-400)
│   └── Propagate_CR3BP, State_Transition_Matrix
│
├── Zero-Velocity Surfaces (lines 405-500)
│   └── Zero_Velocity_Curve, Is_Forbidden_Region
│
└── SPARK Ghost Functions (lines 505-686)
    └── Jacobi_Is_Conserved, Is_Valid_State, validation
```

---

## Alternatives Considered

### Alternative 1: Five Subpackages (Rejected)

**Pros:**
- Matches specification exactly
- Potentially finer-grained compilation units

**Cons:**
- Circular dependencies between CR3BP and Lagrange
- More complex user imports
- No clear benefit at current size
- Deferred features (Periodic, Integrators) not implemented

### Alternative 2: Two Packages (Considered for Future)

If implementation grows significantly:

```
Hale_Orbital.Threebody           -- Core CR3BP, Lagrange, Stability (~600 lines)
Hale_Orbital.Threebody.Advanced  -- Periodic orbits, advanced integrators
```

This would be triggered by:
- ISS-034 implementation (periodic orbits)
- Total lines exceeding 1200

---

## Future Evolution

When periodic orbit computation is implemented (ISS-034), evaluate:

1. **If monodromy/Floquet adds < 300 lines:** Keep in single package
2. **If periodic orbit search is complex:** Create `Hale_Orbital.Threebody.Periodic`
3. **If specialized integrators needed:** Create `Hale_Orbital.Threebody.Integrators`

The current structure supports future splitting without breaking changes:
- All types are in the parent package
- Subpackages would depend on parent, not vice versa

---

## Conclusion

The single-package design is appropriate for the current implementation:
- Cohesive functionality that users typically need together
- Manageable size within Ada guidelines
- Simpler user experience
- Supports future growth and potential splitting

This decision should be revisited when ISS-034 (periodic orbits) is implemented.

---

## Related Decisions

- [DEC-001: Dimensional Types](DEC-001-dimensional-types.md)
- [DEC-002: SPARK Strategy](DEC-002-spark-strategy.md)

## Related Issues

- ISS-033: Three-Body Package Structure Differs From Spec
- ISS-034: Periodic Orbit Computation Not Implemented
