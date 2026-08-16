# DEC-003: Contract Design Principles

## Summary

The HALE Orbital Mechanics Library uses Ada 2012 contracts (Pre/Post conditions) to specify function behavior, catch errors early, and enable formal verification.

## Decision

1. **Preconditions**: Validate input constraints that could cause errors
2. **Postconditions**: Document expected output properties
3. **Type Invariants**: Ensure data structure consistency
4. **Subtype Predicates**: Constrain valid value ranges

## Contract Categories

### 1. Physical Validity Preconditions

Prevent physically impossible inputs:

```ada
function Vis_Viva (R  : Distance_Km;
                   A  : Distance_Km;
                   Mu : Gravitational_Parameter) return Velocity_Km_S
   with Pre => Real (R) > 0.0
               and Real (A) /= 0.0
               and Real (Mu) > 0.0;
```

### 2. Mathematical Constraints

Ensure mathematical operations are valid:

```ada
function Normalize (V : Vector_3D) return Vector_3D
   with Pre => Magnitude_Squared (V) > 0.0;  -- Cannot normalize zero vector

function Solve_Kepler_Elliptic (Mean_Anomaly : Angle_Radians;
                                Eccentricity : Real) return Angle_Radians
   with Pre => Eccentricity >= 0.0 and Eccentricity < 1.0;  -- Elliptic only
```

### 3. Output Guarantees

Document what the function guarantees:

```ada
function Magnitude (V : Vector_3D) return Real
   with Post => Magnitude'Result >= 0.0;  -- Always non-negative

function Normalize (V : Vector_3D) return Vector_3D
   with Post => abs (Magnitude (Normalize'Result) - 1.0) < 1.0e-10;  -- Unit vector
```

### 4. Convergence Guarantees

For iterative solvers:

```ada
function Solve_Lambert (...) return Lambert_Result
   with Post => (if Solve_Lambert'Result.Converged then
                   Solve_Lambert'Result.Iterations <= 100
                   and Real (Solve_Lambert'Result.A) > 0.0);
```

## Rationale

### 1. Documentation as Code

Contracts serve as executable specifications:

```ada
function Transfer_Angle (...) return Angle_Radians
   with Post => Real (Transfer_Angle'Result) >= 0.0
                and Real (Transfer_Angle'Result) <= 2.0 * Pi;
```

This contract documents that the result is always in [0, 2π].

### 2. Early Error Detection

With assertions enabled (`-gnata`), contract violations are caught immediately:

```
raised SYSTEM.ASSERTIONS.ASSERT_FAILURE : failed precondition from hale_orbital-vectors.ads:36
```

### 3. SPARK Proof Enablement

Contracts enable the SPARK prover to verify code correctness:

```
$ gnatprove -P hale_orbital.gpr
vectors.ads:55:19: info: postcondition proved
vectors.ads:65:19: info: precondition proved
```

### 4. Defensive Programming

Contracts enforce input validation at module boundaries:

```ada
--  Caller's responsibility to ensure valid inputs:
V := Normalize (Position);  -- Raises if Position = (0,0,0)
```

## Design Principles

### Principle 1: Fail Fast

Catch errors at the first opportunity:

```ada
function Orbital_Period (A : Distance_Km; Mu : Gravitational_Parameter) return Time_Seconds
   with Pre => Real (A) > 0.0 and Real (Mu) > 0.0;
   -- Better to fail here than return NaN or infinite period
```

### Principle 2: Minimal Preconditions

Only require what's necessary for correctness:

```ada
-- Good: Minimal precondition
function Magnitude (V : Vector_3D) return Real;  -- No precondition needed

-- Bad: Unnecessary restriction
function Magnitude (V : Vector_3D) return Real
   with Pre => V /= Zero_Vector;  -- Over-restrictive
```

### Principle 3: Verifiable Postconditions

Make postconditions that can be proven:

```ada
-- Good: Verifiable property
with Post => Magnitude'Result >= 0.0;

-- Bad: Hard to verify
with Post => Magnitude'Result = Sqrt (V(1)**2 + V(2)**2 + V(3)**2);
-- This just restates the implementation
```

### Principle 4: Tolerance in Postconditions

Account for floating-point precision:

```ada
-- Good: Allows floating-point tolerance
with Post => abs (Magnitude (Normalize'Result) - 1.0) < 1.0e-10;

-- Bad: Exact equality fails due to FP precision
with Post => Magnitude (Normalize'Result) = 1.0;
```

## Contract Patterns

### Pattern 1: Conditional Postcondition

```ada
function Solve (...) return Result
   with Post => (if Solve'Result.Converged then
                   -- Only guarantee properties if converged
                   Solve'Result.Error < Tolerance);
```

### Pattern 2: Range Bounds

```ada
function Normalize_Angle (Angle : Angle_Radians) return Angle_Radians
   with Post => Real (Normalize_Angle'Result) >= 0.0
                and Real (Normalize_Angle'Result) < Two_Pi;
```

### Pattern 3: Relationship Between Inputs and Outputs

```ada
function Elements_To_Position (Elements : Orbital_Elements;
                               Mu : Gravitational_Parameter) return Position_Vector
   with Post => Magnitude (Elements_To_Position'Result) > 0.0;
```

## Trade-offs

### Advantages

1. **Self-documenting**: Contracts specify behavior precisely
2. **Runtime checking**: Catch bugs during testing
3. **Formal verification**: Enable SPARK proofs
4. **API stability**: Contracts are part of the interface

### Disadvantages

1. **Performance overhead**: Assertions cost cycles
2. **Verbosity**: More code to maintain
3. **Complexity**: Learning curve for users

### Mitigations

1. Disable assertions in release builds
2. Focus contracts on key interfaces
3. Provide clear documentation

## Related Decisions

- DEC-001: Dimensional Types (typed parameters in contracts)
- DEC-002: SPARK Strategy (contracts for SPARK verification)

## References

- Ada 2012 Reference Manual, Section 6.1.1 (Preconditions and Postconditions)
- Barnes, J. (2014). Programming in Ada 2012. Cambridge University Press.
- AdaCore. "Introduction to SPARK 2014"
