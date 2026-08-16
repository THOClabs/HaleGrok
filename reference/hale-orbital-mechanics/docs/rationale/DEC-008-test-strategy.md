# DEC-008: Test Strategy Rationale

## Design Decision Record

**ID:** DEC-008
**Title:** Test Strategy Rationale
**Status:** Approved
**Date:** 2026-01-06
**Author:** HALE Development Team

---

## 1. Context

DO-178C requires verification that software meets its requirements. The test strategy must:
- Achieve 100% statement coverage (DAL C)
- Verify requirements are correctly implemented
- Validate against known reference values
- Handle edge cases and error conditions

## 2. Test Strategy Decisions

### 2.1 Test Framework: Custom with AUnit Compatibility

**Selection:** Custom lightweight framework compatible with AUnit patterns

```ada
procedure Assert (Condition : Boolean; Message : String);
procedure Assert_Equal (Actual, Expected : Real; Tolerance : Real);
```

**Rationale:**
- Simple, SPARK-compatible assertions
- No external dependencies
- AUnit-style patterns familiar to Ada developers
- Easy CI integration

### 2.2 Test Categories

| Category | Purpose | Source |
|----------|---------|--------|
| **Vallado Validation** | Verify against published examples | Vallado textbook |
| **Unit Tests** | Individual function verification | Requirements |
| **Integration Tests** | Multi-package workflows | Use cases |
| **Edge Case Tests** | Boundary conditions | Analysis |
| **Parallel Tests** | Concurrent execution | NFRs |
| **Determinism Tests** | Cross-platform reproducibility | NFRs |
| **Negative Tests** | Invalid input handling | Error reqs |
| **Exception Tests** | Error path coverage | Error reqs |

### 2.3 Vallado Validation as Primary Acceptance

**Decision:** Use Vallado's "Fundamentals of Astrodynamics" examples as primary validation source.

**Rationale:**
- Industry-standard reference
- Published, peer-reviewed values
- Covers core algorithms
- Traceable to textbook sections

**Examples Used:**
| Example | Algorithm | Tolerance |
|---------|-----------|-----------|
| 4-1 | State to Elements | 1e-6 |
| 4-4 | Kepler Equation | 1e-10 |
| 6-1 | Hohmann Transfer | 1e-4 |
| 7-1 | Lambert Problem | 1e-8 |

### 2.4 Edge Case Identification

**Method:** Systematic analysis of mathematical singularities and boundaries

| Singularity | Test Approach |
|-------------|---------------|
| Circular (e=0) | Test at e = 1e-10, 1e-12 |
| Equatorial (i=0) | Test at i = 1e-10, 1e-12 |
| Parabolic (e=1) | Test at e = 0.9999, 1.0001 |
| High eccentricity | Test at e = 0.9, 0.99, 0.999 |
| Zero radius | Verify precondition |
| 180° transfer | Lambert degenerate |

### 2.5 Tolerance Selection

**Decision:** Context-specific tolerances based on algorithm characteristics

| Context | Tolerance | Rationale |
|---------|-----------|-----------|
| Kepler solver residual | 1e-12 | Solver tolerance parameter |
| Element round-trip | 1e-10 | Accumulated conversion error |
| Vallado validation | 1e-6 to 1e-8 | Match published precision |
| Energy conservation | 1e-10 relative | Physical invariant |
| Cross-platform | Bit-identical | Deterministic mode |

**Documentation Requirement:** Each tolerance must be documented with rationale.

### 2.6 Negative Testing Strategy (Phase 3)

**Approach:** Systematically test invalid inputs

```ada
-- Test that precondition violation is detected
begin
   Result := Solve_Kepler_Elliptic(M => 1.0, E => 1.5);  -- E >= 1 invalid
   Assert(False, "Should have raised Assertion_Error");
exception
   when Assertion_Error => null;  -- Expected
end;
```

**Categories:**
- Invalid eccentricity (e < 0, e >= 1 for elliptic)
- Invalid radius (r <= 0)
- Invalid mu (mu <= 0)
- NaN/Inf inputs
- Out-of-range anomalies

### 2.7 Coverage Strategy

**Target:** 100% statement coverage for DAL C

**Tools:**
- GNATcoverage for instrumentation
- HTML reports for analysis
- CI integration for regression

**Process:**
1. Run full test suite
2. Generate coverage report
3. Analyze uncovered statements
4. Add tests or document exclusions
5. Verify 100% achieved

## 3. Test-Requirement Traceability

### 3.1 Naming Convention

```
Test_<Package>_<Function>_<Scenario>
```

### 3.2 Requirement Comments

```ada
-- Requirement: HLR-KE-001
-- Validates: Kepler solver convergence for elliptic orbits
procedure Test_Kepler_Solve_Elliptic_Nominal is
```

### 3.3 RTM Updates

Each test procedure traced to requirement in RTM.

## 4. Test Environment

### 4.1 Local Development

```bash
gprbuild -P ada/tests/hale_tests.gpr -XBUILD_MODE=debug
./ada/tests/bin/hale_tests
```

### 4.2 CI/CD Pipeline

```yaml
- build-tests
- run-tests
- generate-coverage
- archive-results
```

### 4.3 SPARK Integration

SPARK proofs complement testing:
- Flow analysis (Level 1)
- RTE absence (Level 2)
- Functional correctness (Level 3+)

## 5. Consequences

### Positive
- Traceable to industry reference
- Systematic edge case coverage
- Automated regression testing
- Certification-ready evidence

### Negative
- Manual tolerance documentation burden
- Negative tests require additional development
- Coverage analysis requires commercial tools

## 6. Compliance

| Requirement | Evidence |
|-------------|----------|
| DO-178C A-6.1 | Test procedures correct |
| DO-178C A-6.3 | HLR coverage |
| DO-178C A-6.4 | LLR coverage |
| DO-178C A-7.5 | Statement coverage |

---

## Revision History

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-01-06 | Initial version |
