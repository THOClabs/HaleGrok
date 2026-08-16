# DEC-002: SPARK Verification Strategy

## Summary

The HALE Orbital Mechanics Library uses SPARK 2014 annotations for formal verification of safety-critical computational packages, with a pragmatic split between verified specifications and implementation-level flexibility.

## Decision

1. **Specification files (.ads)**: Enable `SPARK_Mode => On` for all core packages
2. **Body files (.adb)**: Set `SPARK_Mode => Off` for bodies requiring generic instantiation
3. **Contract-based verification**: Use Pre/Post conditions for interface verification
4. **Gradual adoption**: Start with type safety, expand to full proofs over time

## Package SPARK Status

| Package | Spec SPARK | Body SPARK | Rationale |
|---------|------------|------------|-----------|
| Hale_Orbital | On | Off | String operations |
| Hale_Orbital.Types | On | N/A | Pure types |
| Hale_Orbital.Constants | On | N/A | Pure constants |
| Hale_Orbital.Vectors | On | Off | Generic math functions |
| Hale_Orbital.Matrices | On | Off | Generic math functions |
| Hale_Orbital.Twobody | On | Off | Generic math functions |
| Hale_Orbital.Elements | On | Off | Generic math functions |
| Hale_Orbital.Kepler | On | Off | Generic math functions |
| Hale_Orbital.Lambert | On | Off | Generic math functions |
| Hale_Orbital.Stumpff | On | Off | Generic math functions |
| Hale_Orbital.Maneuvers | On | Off | Generic math functions |
| Hale_Orbital.Propagation | N/A | Off | Interface types |

## Rationale

### 1. Specification-Level Verification

SPARK_Mode on specifications enables:
- Contract verification against specification
- Type flow analysis
- Interface consistency checking

```ada
package Hale_Orbital.Vectors
   with SPARK_Mode => On
is
   function Magnitude (V : Vector_3D) return Real
      with Post => Magnitude'Result >= 0.0;
```

### 2. Implementation Flexibility

Bodies use `Ada.Numerics.Generic_Elementary_Functions` which requires generic instantiation:

```ada
package body Hale_Orbital.Vectors
   with SPARK_Mode => Off  -- Body uses generic instantiation
is
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
```

SPARK does not allow generic instantiation, so body SPARK_Mode is disabled.

### 3. Contract-Driven Development

Even without full body proofs, contracts provide:
- Documentation of expectations
- Runtime assertion checking
- SPARK proof of callers

```ada
function Normalize (V : Vector_3D) return Vector_3D
   with Pre  => Magnitude_Squared (V) > 0.0,
        Post => abs (Magnitude (Normalize'Result) - 1.0) < 1.0e-10;
```

### 4. Safety-Critical Heritage

Orbital mechanics libraries may be used in:
- Mission planning tools
- Flight software validation
- Educational simulators

SPARK compatibility enables certification pathways (DO-178C, ECSS-E-ST-40C).

## Proof Strategy

### Phase 1: Type Safety (Current)

- SPARK_Mode on all specifications
- Basic Pre/Post contracts
- No body proofs required

### Phase 2: Interface Proofs (Future)

- Add `Global => null` annotations
- Add `Depends` clauses
- Prove specification contracts

### Phase 3: Numerical Proofs (Implemented - ISS-019)

Ghost functions have been added for mathematical property verification:

**Vectors Package (hale_orbital-vectors.ads):**
- `Is_Valid_Magnitude`: Verifies magnitude >= 0
- `Is_Unit_Vector`: Verifies normalized vectors have |v| = 1
- `Are_Orthogonal`: Verifies perpendicular vectors (a · b = 0)
- `Cross_Product_Is_Orthogonal`: Proves (a × b) ⊥ a and (a × b) ⊥ b
- `Dot_Is_Commutative`: Proves a · b = b · a
- `Rotation_Preserves_Magnitude`: Proves ||R(v)|| = ||v||

**Threebody Package (hale_orbital-threebody.ads):**
- `Jacobi_Is_Conserved`: Verifies C_J(t) = C_J(0) for all t (energy integral)
- `Is_Valid_State`: Verifies state not at singularities (primary bodies)
- `Is_Above_Zero_Velocity_Surface`: Verifies valid motion constraint C_J >= 2Ω

**Still Needed:**
- Loop invariants for iterative solvers (Kepler, Lambert)
- Full floating-point proof annotations with alt-ergo provers

---

## Comprehensive Proof Strategy (ISS-036)

This section documents a systematic approach to expanding SPARK formal verification coverage with achievable milestones.

### Current Architecture Constraints

The library uses a pragmatic SPARK architecture where:
- **Specifications**: Full SPARK_Mode => On (verifiable)
- **Bodies**: SPARK_Mode => Off due to generic instantiation requirement

This constraint arises from:
```ada
package body Hale_Orbital.Vectors
   with SPARK_Mode => Off
is
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
```

SPARK does not support generic instantiation, and `Ada.Numerics.Generic_Elementary_Functions` provides essential transcendental functions (Sin, Cos, Sqrt, Arctan, etc.).

### Verification Levels

#### Level 0: Type Safety (ACHIEVED)
- All dimensional types prevent unit confusion at compile time
- SPARK_Mode on specifications enables flow analysis
- Type constraints catch invalid values

**Evidence**: Types like `Distance_Km`, `Velocity_Km_S`, `Angle_Radians` prevent mixing incompatible units.

#### Level 1: Contract Verification (ACHIEVED)
- Pre/Post conditions on all public functions
- Runtime checking available with `-gnata`
- Documents interface requirements

**Coverage**: ~95% of public functions have Pre/Post contracts

#### Level 2: Data Flow Analysis (PARTIAL)
- `Global => null` on pure functions
- No hidden state dependencies
- Verifiable side-effect freedom

**Current Status**: ~60% coverage, needs expansion

#### Level 3: Information Flow (PLANNED)
- `Depends` clauses showing output dependencies
- Complete data flow traceability
- Required for DO-178C Level A credit

**Current Status**: Not yet implemented

#### Level 4: Functional Correctness (PARTIAL)
- Ghost functions for mathematical properties
- Loop invariants for iterative algorithms
- Termination proofs

**Current Status**: Ghost functions implemented; loop invariants partial

### Achievable Proof Milestones

#### Milestone A: Complete Global Annotations (Effort: Small)
Add `Global => null` to all pure computational functions:

```ada
function Magnitude (V : Vector_3D) return Real
   with Global => null,
        Post   => Magnitude'Result >= 0.0;
```

**Packages**: Vectors, Matrices, Types, Constants
**Benefit**: Proves no hidden state access
**Estimated VCs**: ~50

#### Milestone B: Depends Clauses for Stateless Functions (Effort: Medium)
Add explicit input/output dependencies:

```ada
function Cross (A, B : Vector_3D) return Vector_3D
   with Global  => null,
        Depends => (Cross'Result => (A, B));
```

**Packages**: Vectors, Matrices, Twobody
**Benefit**: Complete data flow traceability
**Estimated VCs**: ~100

#### Milestone C: Loop Invariant Expansion (Effort: Medium)
Strengthen existing loop invariants:

```ada
--  Kepler solver (existing)
pragma Loop_Invariant (Iter < Max_Iterations);

--  Enhanced with convergence bound
pragma Loop_Invariant (Iter < Max_Iterations);
pragma Loop_Invariant (abs (E_New - E_Old) <= abs (E_Initial) * (0.5 ** Iter));
```

**Packages**: Kepler, Lambert
**Benefit**: Proves termination and convergence rate
**Estimated VCs**: ~30

#### Milestone D: Ghost Function Proof Completion (Effort: Large)
Run GNATprove on existing Ghost functions:

```ada
function Is_Unit_Vector (V : Vector_3D) return Boolean is
   (abs (Magnitude (V) - 1.0) < 1.0e-10)
with Ghost;

--  Prove: Normalize'Result satisfies Is_Unit_Vector
```

**Packages**: Vectors, Threebody, Elements
**Benefit**: Mathematically verified invariants
**Estimated VCs**: ~80

### Proof Coverage Matrix

| Package | Level 0 | Level 1 | Level 2 | Level 3 | Level 4 |
|---------|:-------:|:-------:|:-------:|:-------:|:-------:|
| Types | ✓ | ✓ | ✓ | N/A | N/A |
| Constants | ✓ | N/A | ✓ | N/A | N/A |
| Vectors | ✓ | ✓ | Partial | Planned | Partial |
| Matrices | ✓ | ✓ | Partial | Planned | - |
| Twobody | ✓ | ✓ | Partial | Planned | - |
| Elements | ✓ | ✓ | - | Planned | - |
| Kepler | ✓ | ✓ | - | Planned | Partial |
| Lambert | ✓ | ✓ | - | Planned | - |
| Stumpff | ✓ | ✓ | - | Planned | - |
| Maneuvers | ✓ | ✓ | - | Planned | - |
| Propagation | ✓ | ✓ | - | - | - |
| Threebody | ✓ | ✓ | - | Planned | Partial |

Legend: ✓ = Complete, Partial = In Progress, Planned = Milestone target, - = Not applicable/planned

### GNATprove Configuration

Recommended proof settings for incremental verification:

```
[gnatprove]
; Start with basic flow analysis
mode = flow
; Expand to proof when flow passes
; mode = all
; Timeout per VC (seconds)
timeout = 60
; Prover selection
provers = cvc5,z3,alt-ergo
; Proof level (0-4)
level = 2
```

### Limitations and Workarounds

#### 1. Generic Instantiation in Bodies

**Problem**: SPARK disallows generic instantiation
**Workaround**: SPARK_Mode => Off for bodies
**Impact**: Body-level proofs not possible
**Mitigation**: Contract proofs still verify interface correctness

#### 2. Floating-Point Arithmetic

**Problem**: Floating-point proofs require specialized prover support
**Workaround**: Use Alt-Ergo with float theory, tolerance-based contracts
**Impact**: Exact numerical equality not provable
**Mitigation**: Ghost functions check properties with tolerance

#### 3. Transcendental Functions

**Problem**: Sin, Cos, Sqrt not natively proven
**Workaround**: Trust Ada.Numerics implementation
**Impact**: Cannot prove properties of transcendental results
**Mitigation**: Validated test suite demonstrates correctness

### Certification Credit (DO-333)

Under DO-333 Formal Methods Supplement:

| Proof Level | Credit Available |
|-------------|------------------|
| Data flow analysis | Reduce code review |
| Information flow | Reduce integration testing |
| Functional correctness | Substitute for low-level testing |

Current library achieves credit for:
- ✓ Data flow analysis (specification level)
- ✓ Partial information flow
- ○ Functional correctness (Ghost functions, not full proofs)

### Roadmap

| Phase | Milestone | Effort | Benefit |
|-------|-----------|--------|---------|
| 1 | Complete Global annotations | 2 weeks | Flow analysis complete |
| 2 | Add Depends clauses | 3 weeks | Information flow verified |
| 3 | Expand loop invariants | 2 weeks | Termination proofs |
| 4 | GNATprove Ghost functions | 4 weeks | Mathematical correctness |
| 5 | DO-333 certification package | 6 weeks | Full formal methods credit |

**Total Estimated Effort**: 17 person-weeks for full Level 2 coverage

---

## Trade-offs

### Advantages

1. **Gradual Adoption**: Can be used without full SPARK infrastructure
2. **Practical**: Allows standard Ada math library usage
3. **Documented Intent**: Contracts serve as specifications

### Disadvantages

1. **Incomplete Coverage**: Bodies not formally verified
2. **Runtime Costs**: Contracts add assertion overhead
3. **Complexity**: SPARK annotations increase code size

## Alternatives Considered

### 1. Full SPARK Implementation

Reimplement elementary functions in SPARK-compatible code.

**Rejected because**:
- Significant effort
- Standard library already validated
- Not justified for initial release

### 2. No SPARK

Skip SPARK annotations entirely.

**Rejected because**:
- Loses certification pathway
- Misses contract documentation benefits
- Not aligned with Ada best practices

### 3. SPARK 2005 Subset

Use older SPARK without Ada 2012 contracts.

**Rejected because**:
- Outdated tooling
- More restrictive subset
- Ada 2012 contracts are more expressive

## Implementation Notes

### Enabling SPARK Mode

```ada
package Example
   with SPARK_Mode => On
is
   -- Specification content
end Example;

package body Example
   with SPARK_Mode => Off
is
   -- Implementation with generics
end Example;
```

### Contract Assertions

During development, enable contract checking:

```
gnatmake -gnata program.adb  -- Enable assertions
```

For production, disable for performance:

```
gnatmake program.adb  -- Assertions disabled by default
```

## Related Decisions

- DEC-001: Dimensional Types (SPARK-compatible types)
- DEC-003: Contract Design (contracts for SPARK proofs)

## References

- AdaCore SPARK 2014 User's Guide
- Barnes, J. (2012). High Integrity Software: The SPARK Approach to Safety and Security
- ISO/IEC 8652:2012 (Ada 2012 Standard)
