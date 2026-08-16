# DEC-001: Dimensional Types Design Decision

## Summary

The HALE Orbital Mechanics Library uses Ada's strong typing to enforce dimensional correctness at compile time through distinct numeric types for each physical unit.

## Decision

Create separate types for each physical dimension:

```ada
type Distance_Km is new Real;
type Velocity_Km_S is new Real;
type Time_Seconds is new Real;
type Angle_Radians is new Real;
type Mass_Kg is new Real;
type Gravitational_Parameter is new Real;
type Specific_Energy is new Real;
type Specific_Angular_Momentum is new Real;
```

## Rationale

### 1. Compile-Time Unit Safety

The primary benefit is catching unit mismatches at compile time rather than runtime:

```ada
-- This will NOT compile (type mismatch):
Distance : Distance_Km := 1000.0;
Velocity : Velocity_Km_S := Distance;  -- Compile error!

-- Must use explicit conversion if intentional:
Velocity := Velocity_Km_S (Distance);  -- Developer acknowledges unit change
```

### 2. Historical Precedent

The Mars Climate Orbiter loss (1999) was caused by a unit mismatch between imperial and metric systems. Ada's type system prevents such errors when properly used.

### 3. Self-Documenting Code

Type names document the expected units:

```ada
function Vis_Viva (R  : Distance_Km;
                   A  : Distance_Km;
                   Mu : Gravitational_Parameter) return Velocity_Km_S;
```

The signature alone tells you:
- R and A are distances in kilometers
- Mu is a gravitational parameter (km³/s²)
- Returns velocity in km/s

### 4. API Clarity

When calling functions, the types enforce correct parameter order:

```ada
-- Cannot accidentally swap R and A with Mu:
V := Vis_Viva (R => Orbit_Radius,
               A => Semi_Major,
               Mu => Mu_Earth);
```

## Trade-offs

### Disadvantages

1. **Type Conversion Overhead**: Explicit conversions required for mixed operations
2. **Verbosity**: More type annotations needed
3. **Learning Curve**: Users must understand type system

### Mitigations

1. Operations defined on typed quantities reduce conversion needs
2. Ada's strong typing is idiomatic for safety-critical code
3. Clear documentation and examples

## Alternatives Considered

### 1. Raw Float Types

```ada
function Vis_Viva (R, A, Mu : Real) return Real;  -- Rejected
```

**Rejected because**: No compile-time unit checking, error-prone.

### 2. Units-of-Measurement Packages

Generic units packages (like Ada.Numerics.Big_Integers) provide automatic conversion.

**Not chosen because**:
- Adds complexity
- Most orbital mechanics uses consistent units (km, s)
- Performance overhead for generic instantiation

### 3. Tagged Types with Units

```ada
type Quantity is tagged record
   Value : Real;
   Units : Unit_Type;
end record;
```

**Rejected because**: Runtime overhead, not SPARK-compatible, excessive complexity.

## Implementation Notes

### Standard Units

All library calculations use:
- Distance: kilometers (km)
- Time: seconds (s)
- Angles: radians (internal), degrees (documentation)
- Gravitational parameters: km³/s²

### Conversion Functions

The library provides conversion constants:

```ada
Deg_To_Rad : constant Real := Pi / 180.0;
Rad_To_Deg : constant Real := 180.0 / Pi;
```

## Related Decisions

- DEC-002: SPARK Strategy (types are SPARK-compatible)
- DEC-003: Contract Design (contracts use typed parameters)

## References

- Hale, F.J. (1994). Introduction to Space Flight. Prentice Hall.
- Mars Climate Orbiter Mishap Investigation Board Report (1999)
- Barnes, J. (2014). Programming in Ada 2012. Cambridge University Press.
