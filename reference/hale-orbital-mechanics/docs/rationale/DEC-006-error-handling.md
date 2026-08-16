# DEC-006: Error Handling Strategy

## Design Decision Record

**ID:** DEC-006
**Title:** Error Handling Strategy
**Status:** Approved
**Date:** 2026-01-06
**Author:** HALE Development Team

---

## 1. Context

The HALE Orbital Mechanics Library performs safety-relevant computations. A clear error handling strategy is essential for:
- Predictable behavior when inputs are invalid
- Detectable failures for upstream validation
- Certification compliance (DO-178C requires documented error handling)

## 2. Decision

We adopt a **contract-first with exceptions as backup** error handling strategy:

### 2.1 Primary: Ada Contracts (Pre/Post Conditions)

Invalid inputs are prevented through preconditions:

```ada
function Solve_Kepler_Elliptic (M : Real; E : Real) return Real
   with Pre => E >= 0.0 and E < 1.0 and M >= 0.0;
```

**Rationale:**
- Checked at call site (with `-gnata`)
- Provable with SPARK
- Self-documenting requirements
- Compile-time visibility

### 2.2 Secondary: Convergence Flags

Iterative algorithms return convergence status:

```ada
type Lambert_Solution is record
   V1        : Velocity_Vector;
   V2        : Velocity_Vector;
   A         : Distance_Km;
   Converged : Boolean;  -- Caller MUST check
end record;
```

**Rationale:**
- Non-exceptional failure mode
- Caller can handle gracefully
- No performance overhead
- Compatible with SPARK

### 2.3 Tertiary: Exceptions

Exceptions for unrecoverable errors:

| Exception | When Raised | Package |
|-----------|-------------|---------|
| `Convergence_Error` | Max iterations exceeded (optional) | Kepler, Lambert |
| `Invalid_Orbit` | Physically impossible orbit | Elements |
| `Physical_Error` | Physics violation detected | Twobody |
| `Singularity_Error` | Singular configuration | Elements |

**Rationale:**
- Ada idiomatic for unexpected conditions
- Clear separation from normal flow
- Testable with exception handlers

## 3. Alternatives Considered

### 3.1 Error Codes (Rejected)

Returning error codes:
```ada
function Solve_Kepler (...) return Real;
function Get_Last_Error return Error_Code;
```

**Rejected because:**
- Not thread-safe without TLS
- Easy to ignore return codes
- Not idiomatic Ada
- Harder to trace

### 3.2 Result Types (Partially Adopted)

Using discriminated records:
```ada
type Result (Success : Boolean) is record
   case Success is
      when True  => Value : Real;
      when False => Error : Error_Code;
   end case;
end record;
```

**Adopted for Lambert solver** (Converged flag) but not universally because:
- More verbose for simple functions
- Overhead for performance-critical paths
- Preconditions handle most cases

### 3.3 Assertions Only (Rejected)

Relying solely on `pragma Assert`:

**Rejected because:**
- Disabled in release builds by default
- Not SPARK verifiable as contracts
- Less visible in specifications

## 4. Implementation Guidelines

### 4.1 For Function Authors

1. **Add preconditions** for all input constraints
2. **Add postconditions** for output guarantees
3. **Return Converged flag** for iterative algorithms
4. **Raise exceptions** only for programming errors

### 4.2 For Library Users

1. **Enable assertions** with `-gnata` during development
2. **Check Converged flags** before using results
3. **Handle exceptions** at application boundary
4. **Use SPARK proof** to verify preconditions

### 4.3 For Certification

1. **Document all exceptions** in RTM Section 12
2. **Test exception paths** (Phase 3)
3. **Prove preconditions sufficient** with SPARK

## 5. Consequences

### Positive
- Clear documentation of valid inputs
- SPARK provable for critical properties
- Flexible handling (check vs catch)
- Testable error conditions

### Negative
- Preconditions not checked in release mode (mitigated by proof)
- Multiple error mechanisms to understand
- Exception testing requires additional tests

## 6. Compliance

| Requirement | Evidence |
|-------------|----------|
| DO-178C 6.3.3 | Documented error handling |
| ERR-EXC-001 to 004 | Exception definitions |
| ERR-DET-001 to 005 | Detection requirements |

---

## Revision History

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-01-06 | Initial version |
