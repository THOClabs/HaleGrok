# DEC-004: Floating-Point Determinism Strategy

## Summary

The HALE Orbital Mechanics Library implements strategies to ensure floating-point
calculation reproducibility across different platforms, compilers, and optimization
levels. This is critical for mission-critical applications where bitwise identical
results may be required.

## Decision

1. **Deterministic Build Mode**: Provide a `deterministic` build mode with strict FP flags
2. **IEEE 754 Compliance**: Enforce strict IEEE 754 semantics where needed
3. **Algorithm Design**: Use numerically stable algorithms that minimize platform variance
4. **Validation Testing**: Provide tests to detect FP non-determinism

## Build Modes

### Standard Modes

| Mode | Use Case | FP Behavior |
|------|----------|-------------|
| debug | Development | Standard, assertions enabled |
| release | Production | Optimized, some FP latitude |
| spark | Verification | No optimization |
| **deterministic** | Cross-platform | Strict IEEE 754 |

### Deterministic Mode Flags

```
-ffp-contract=off     # Disable FMA (fused multiply-add) contractions
-fno-fast-math        # Disable unsafe FP optimizations
-frounding-math       # Honor dynamic rounding mode changes
-fsignaling-nans      # Signal on NaN operations
```

## Sources of Non-Determinism

### 1. FMA (Fused Multiply-Add) Operations

Modern CPUs have FMA instructions that compute `a*b+c` in a single operation
with only one rounding step (instead of two). This produces more accurate
results but different from the standard multiply-then-add sequence.

**Mitigation**: Use `-ffp-contract=off` to disable automatic FMA generation.

### 2. Expression Evaluation Order

The compiler may reorder floating-point operations for optimization:
```ada
--  These may produce different results:
X := (A + B) + C;
Y := A + (B + C);
```

**Mitigation**: Use parentheses explicitly and `-fno-fast-math`.

### 3. Extended Precision

x86 FPU uses 80-bit extended precision internally, while SSE/AVX uses 64-bit.
Different code paths may use different precision.

**Mitigation**: Ada's `Machine_Overflows` and explicit type conversions help,
but platform differences remain. Document expected precision.

### 4. Transcendental Functions

`sin`, `cos`, `sqrt`, `exp`, etc. may have different implementations across
platforms and math libraries.

**Mitigation**:
- Use well-defined algorithms (e.g., Stumpff functions instead of trig)
- Document expected accuracy tolerances
- Consider custom implementations for critical paths

### 5. Compiler Version and Optimization

Different compiler versions and optimization levels can change code generation.

**Mitigation**:
- Pin compiler versions in CI
- Test across multiple compilers
- Use deterministic mode for validation

## Algorithm Design Guidelines

### Numerically Stable Patterns

1. **Avoid Catastrophic Cancellation**
   ```ada
   --  Bad: loses precision when A ≈ B
   Result := A - B;

   --  Better: reformulate to avoid subtraction
   Result := (A_Sq - B_Sq) / (A + B);  -- if computing A - B from squares
   ```

2. **Use Kahan Summation** for accumulating many values:
   ```ada
   Sum := 0.0;
   C := 0.0;  -- Running compensation for lost low-order bits
   for X of Values loop
      Y := X - C;
      T := Sum + Y;
      C := (T - Sum) - Y;
      Sum := T;
   end loop;
   ```

3. **Stumpff Functions** instead of direct trig:
   - `C(z)` and `S(z)` are well-defined for all z
   - Avoid branch between elliptic/hyperbolic cases
   - Series expansion near z=0 is stable

### Tolerance Design

Define tolerances based on expected precision:
```ada
--  For IEEE 754 double precision:
Epsilon : constant := 2.220446049250313E-16;  -- Machine epsilon

--  Recommended tolerances:
Tight    : constant := 1.0e-12;  -- ~4500 * epsilon
Standard : constant := 1.0e-10;  -- ~450000 * epsilon
Relaxed  : constant := 1.0e-6;   -- For cross-platform validation
```

## Validation Tests

### Single-Platform Determinism Test

Verifies that repeated calculations produce identical results:

```ada
procedure Test_Determinism is
   R1 : constant State_Vector := Propagate (...);
   R2 : constant State_Vector := Propagate (...);  -- Same inputs
begin
   Assert (R1.Position = R2.Position);  -- Bitwise equal
   Assert (R1.Velocity = R2.Velocity);
end Test_Determinism;
```

### Cross-Platform Reference Values

Store reference values computed on a canonical platform:

```ada
--  Reference: Computed on Linux x86_64, GNAT 13, deterministic mode
Hohmann_LEO_GEO_DV1 : constant := 2.457_368_492_847_123;
Hohmann_LEO_GEO_DV2 : constant := 1.478_231_847_293_847;
```

### CI Matrix

Test across platforms in CI:

| Platform | Compiler | Mode | Status |
|----------|----------|------|--------|
| Linux x86_64 | GNAT 12 | deterministic | Reference |
| Linux x86_64 | GNAT 13 | deterministic | Validate |
| Windows x86_64 | GNAT 13 | deterministic | Validate |
| macOS ARM64 | GNAT 13 | deterministic | Validate |

## Implementation Status

### Completed

- [x] Deterministic build mode in hale_orbital.gpr
- [x] Documentation of FP determinism strategy
- [x] Numerically stable Stumpff functions
- [x] Tolerance-based test assertions

### Future Work

- [ ] Cross-platform CI matrix validation
- [ ] Reference value database
- [ ] Platform-specific documentation
- [ ] Custom math functions for critical paths (if needed)

## Trade-offs

### Advantages

1. **Reproducibility**: Same inputs produce same outputs across runs
2. **Debugging**: Easier to isolate issues with deterministic behavior
3. **Validation**: Can verify against reference implementations
4. **Certification**: Required for some safety-critical applications

### Disadvantages

1. **Performance**: Deterministic mode ~10-20% slower than release
2. **Complexity**: Additional build mode and testing burden
3. **Not Perfect**: Some platform differences may remain

## References

- IEEE 754-2019: Standard for Floating-Point Arithmetic
- Goldberg, D. (1991). "What Every Computer Scientist Should Know About Floating-Point Arithmetic"
- Monniaux, D. (2008). "The pitfalls of verifying floating-point computations"
- GNAT User's Guide: Floating Point Operations
