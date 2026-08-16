# DO-178C Level C Certification Roadmap

**Document Version:** 1.0
**Created:** 2026-01-06
**Target:** DAL C (Major Failure Condition)
**Baseline:** Consultant Assessment dated 2026-01-06

---

## Overview

This roadmap provides a phased approach to achieving DO-178C Level C certification for the HALE Orbital Mechanics Library. It addresses all 71 issues identified in the compliance review (`compliance-issues.csv`) through four distinct phases.

### Timeline Summary

```
Phase 1: Foundation & Documentation    [Weeks 1-6]
Phase 2: Contract Strengthening        [Weeks 7-10]
Phase 3: Test Completeness             [Weeks 11-16]
Phase 4: Verification & Closure        [Weeks 17-19]
```

### Success Criteria

| Metric | Target |
|--------|--------|
| Critical Issues Resolved | 21/21 (100%) |
| Major Issues Resolved | 40/40 (100%) |
| Statement Coverage | ≥ 100% |
| SPARK Flow Analysis | PASS |
| Formal Documentation | Complete |

---

## Phase 1: Foundation & Documentation (Weeks 1-6)

### Objective
Establish formal certification infrastructure and resolve documentation blockers.

### 1.1 Formal Certification Documents (Week 1-3)

#### SCMP - Software Configuration Management Plan
**Issues Addressed:** ISS-017, ISS-021, ISS-058, ISS-059, ISS-060

| Task | Deliverable | Owner | Status |
|------|-------------|-------|--------|
| Document Git branching strategy | SCMP Section 4.1 | | ☐ |
| Define baseline identification | SCMP Section 4.2 | | ☐ |
| Document change control procedure | SCMP Section 4.3 | | ☐ |
| Define CI list and naming | SCMP Section 4.4 | | ☐ |
| Document release procedure | SCMP Section 4.5 | | ☐ |
| Create CR/PR template | `.github/PULL_REQUEST_TEMPLATE.md` | | ☐ |

**Template Location:** `docs/certification/templates/SCMP-template.md`

#### SQAP - Software Quality Assurance Plan
**Issues Addressed:** ISS-018

| Task | Deliverable | Owner | Status |
|------|-------------|-------|--------|
| Define QA independence | SQAP Section 3 | | ☐ |
| Document review procedures | SQAP Section 4 | | ☐ |
| Define audit schedule | SQAP Section 5 | | ☐ |
| Create problem report procedure | SQAP Section 6 | | ☐ |
| Document noncompliance process | SQAP Section 7 | | ☐ |

#### SDP - Software Development Plan
**Issues Addressed:** ISS-015

| Task | Deliverable | Owner | Status |
|------|-------------|-------|--------|
| Document development lifecycle | SDP Section 3 | | ☐ |
| Define coding standards | SDP Section 4 | | ☐ |
| Document tool environment | SDP Section 5 | | ☐ |
| Define review gates | SDP Section 6 | | ☐ |

#### SVP - Software Verification Plan
**Issues Addressed:** ISS-016

| Task | Deliverable | Owner | Status |
|------|-------------|-------|--------|
| Define verification methods | SVP Section 3 | | ☐ |
| Document test strategy | SVP Section 4 | | ☐ |
| Define coverage objectives | SVP Section 5 | | ☐ |
| Document SPARK proof strategy | SVP Section 6 | | ☐ |

#### PSAC - Plan for Software Aspects of Certification
**Issues Addressed:** ISS-014

| Task | Deliverable | Owner | Status |
|------|-------------|-------|--------|
| Define certification scope | PSAC Section 2 | | ☐ |
| Document compliance approach | PSAC Section 3 | | ☐ |
| Identify deviations/exemptions | PSAC Section 4 | | ☐ |
| Define certification liaison | PSAC Section 5 | | ☐ |

### 1.2 Requirements Traceability Expansion (Week 3-4)

**Issues Addressed:** ISS-019, ISS-020, ISS-057

| Task | RTM Section | Status |
|------|-------------|--------|
| Add non-functional requirements | Section 10 | ☐ |
| Add performance requirements | Section 10.1 | ☐ |
| Add accuracy requirements | Section 10.2 | ☐ |
| Add error handling requirements | Section 11 | ☐ |
| Document exception conditions | Section 11.1 | ☐ |
| Add dependency requirements | Section 12 | ☐ |
| Add GNAT version requirements | Section 12.1 | ☐ |
| Add platform requirements | Section 12.2 | ☐ |

### 1.3 Design Rationale Documents (Week 4-5)

**Issues Addressed:** ISS-054, ISS-055, ISS-056

| Document | Content | Status |
|----------|---------|--------|
| DEC-006: Error Handling Strategy | Exception taxonomy, recovery approach | ☐ |
| DEC-007: Algorithm Selection | Why Newton-Raphson, Stumpff, etc. | ☐ |
| DEC-008: Test Strategy | Coverage approach, boundary selection | ☐ |
| DEC-009: Numerical Thresholds | Mathematical justification for all 1.0e-15 values | ☐ |

### 1.4 API Documentation Completion (Week 5-6)

**Issues Addressed:** ISS-051, ISS-052, ISS-053, ISS-069

| Task | File | Status |
|------|------|--------|
| Document all exception conditions | api-reference.md Section 7 | ☐ |
| Add performance requirements | api-reference.md Section 5 | ☐ |
| Add accuracy by orbital regime | api-reference.md Section 6 | ☐ |
| Document deterministic mode impact | api-reference.md Section 8 | ☐ |

### Phase 1 Exit Criteria

- [ ] All 5 formal plans created (PSAC, SDP, SVP, SCMP, SQAP)
- [ ] RTM expanded to 100+ requirements including NFRs
- [ ] DEC-006 through DEC-009 complete
- [ ] API reference fully documents exceptions and performance
- [ ] All Phase 1 issues closed in compliance-issues.csv

---

## Phase 2: Contract Strengthening (Weeks 7-10)

### Objective
Resolve all critical and major contract issues to enable SPARK verification.

### 2.1 Critical Pre-Condition Additions (Week 7)

**Issues Addressed:** ISS-005, ISS-006, ISS-022, ISS-023, ISS-024, ISS-025

| Function | Package | Pre-Condition to Add | Status |
|----------|---------|---------------------|--------|
| `Specific_Energy` | twobody | `Magnitude(R) > 1.0e-10 and Mu > 0.0` | ☐ |
| `Vis_Viva` | twobody | `R > 0.0 and abs(A) > 1.0e-10 and Mu > 0.0` | ☐ |
| `Orbital_Period` | twobody | `A > 0.0 and Mu > 0.0` | ☐ |
| `True_To_Eccentric_Anomaly` | elements | `E >= 0.0 and E < 1.0` | ☐ |
| `True_To_Hyperbolic_Anomaly` | elements | `E > 1.0` | ☐ |
| `Solve_Lambert_Multi` | lambert | Match `Solve_Lambert` Pre | ☐ |

### 2.2 Critical Post-Condition Additions (Week 7-8)

**Issues Addressed:** ISS-001, ISS-002, ISS-003, ISS-004

| Function | Package | Post-Condition to Add | Status |
|----------|---------|----------------------|--------|
| `Solve_Kepler_Elliptic` | kepler | `Result in 0.0 .. Two_Pi and abs(Result - E*Sin(Result) - M) < Tol` | ☐ |
| `Solve_Kepler_Hyperbolic` | kepler | `abs(E*Sinh(Result) - Result - M) < Tol` | ☐ |
| `Solve_Kepler_Parabolic` | kepler | Pre + Post for D parameter | ☐ |
| `Solve_Lambert` | lambert | `(Converged => A > 0 and E >= 0 and V1_Valid and V2_Valid)` | ☐ |

### 2.3 Output Range Contracts (Week 8-9)

**Issues Addressed:** ISS-034, ISS-035, ISS-036, ISS-037, ISS-038

| Function | Package | Post-Condition to Add | Status |
|----------|---------|----------------------|--------|
| `Specific_Energy` | twobody | Document energy interpretation | ☐ |
| `Vis_Viva` | twobody | `Result >= 0.0` | ☐ |
| `Circular_Velocity` | twobody | `Result > 0.0` | ☐ |
| `Solve_Kepler_Universal` | kepler | Valid state production | ☐ |
| `True_To_Mean_Anomaly` | elements | `Result >= 0.0 and Result < Two_Pi` | ☐ |

### 2.4 Loop Invariant Strengthening (Week 9-10)

**Issues Addressed:** ISS-027, ISS-028, ISS-029, ISS-030, ISS-031

| Location | Package | Invariant to Add | Status |
|----------|---------|-----------------|--------|
| `Solve_Kepler_Elliptic` loop | kepler | F_Prime bounds, Delta monotonicity | ☐ |
| `Solve_Kepler_Hyperbolic` loop | kepler | Derivative bounds, convergence | ☐ |
| `Solve_Kepler_Universal` loop | kepler | Z range, R_Mag positive | ☐ |
| `Solve_Lambert` bisection | lambert | Z_Low < Z < Z_High, F sign bracket | ☐ |
| `Normalize_Angle` while | elements | Convergence to [0, 2π) | ☐ |

### 2.5 Numerical Threshold Documentation (Week 10)

**Issues Addressed:** ISS-007, ISS-008, ISS-009, ISS-010, ISS-026

| Threshold | Location | Documentation Required | Status |
|-----------|----------|----------------------|--------|
| 1.0e-15 denominator | twobody:164 | Condition number analysis | ☐ |
| 1.0e-15 SMA | twobody:177 | Precision loss justification | ☐ |
| 1.0e-15 F_Prime | kepler:51 | Problem conditioning | ☐ |
| C_Z > 0 guards | lambert:154 | SPARK proof or explicit guard | ☐ |
| Tanh guard | elements:447 | Epsilon margin justification | ☐ |

### Phase 2 Exit Criteria

- [ ] All functions have complete Pre conditions
- [ ] All solver functions have meaningful Post conditions
- [ ] All iterative loops have convergence invariants
- [ ] All numerical thresholds documented in DEC-009
- [ ] SPARK flow analysis passes on all specifications
- [ ] All Phase 2 issues closed in compliance-issues.csv

---

## Phase 3: Test Completeness (Weeks 11-16)

### Objective
Achieve 100% statement coverage with comprehensive boundary and exception testing.

### 3.1 Negative Test Suite (Week 11-12)

**Issues Addressed:** ISS-011

| Test Category | Package | Test Cases | Status |
|---------------|---------|------------|--------|
| Invalid eccentricity | kepler | e = 1.0, e = 1.001, e = -0.1 | ☐ |
| Invalid SMA | twobody | a = 0, a < 0 | ☐ |
| Invalid radius | twobody | r = 0, r < 0 | ☐ |
| Invalid Mu | all | Mu = 0, Mu < 0 | ☐ |
| NaN inputs | all | Propagate NaN through | ☐ |
| Inf inputs | all | Handle overflow | ☐ |
| Below minimum TOF | lambert | TOF < parabolic limit | ☐ |

**Deliverable:** `ada/tests/hale_tests-negative.adb`

### 3.2 Exception Path Tests (Week 12-13)

**Issues Addressed:** ISS-012

| Exception | Package | Test Approach | Status |
|-----------|---------|--------------|--------|
| `Assertion_Error` | all | Call with Pre violation, catch | ☐ |
| `Convergence_Error` | kepler, lambert | Force non-convergence | ☐ |
| `Invalid_Orbit` | elements | Invalid orbital elements | ☐ |
| `Physical_Error` | twobody | Impossible physics | ☐ |
| `Singularity_Error` | elements | Singular configurations | ☐ |
| `Constraint_Error` | propagation | Array bounds | ☐ |

**Deliverable:** `ada/tests/hale_tests-exceptions.adb`

### 3.3 Boundary Condition Tests (Week 13-14)

**Issues Addressed:** ISS-045

| Boundary | Package | Test Values | Status |
|----------|---------|-------------|--------|
| e → 0 (circular) | elements | 1e-10, 1e-12, 1e-15 | ☐ |
| e → 1 (parabolic) | kepler | 0.9999, 0.999999, 0.9999999 | ☐ |
| e > 1 (hyperbolic) | kepler | 1.0001, 1.001, 1.1 | ☐ |
| i → 0 (equatorial) | elements | 1e-10, 1e-12 | ☐ |
| i → π (retrograde) | elements | π - 1e-10 | ☐ |
| ν = 0, π, 2π | elements | Exact boundary values | ☐ |
| M = 0, π, 2π | kepler | Exact boundary values | ☐ |

**Deliverable:** `ada/tests/hale_tests-boundaries.adb`

### 3.4 Periodic Orbit Tests (Week 14-15)

**Issues Addressed:** ISS-013

| Test | Requirement | Verification | Status |
|------|-------------|--------------|--------|
| Find Lyapunov L1 | HLR-3B-033 | Orbit closure < tolerance | ☐ |
| Find Lyapunov L2 | HLR-3B-033 | Period accuracy | ☐ |
| Find Halo Northern | HLR-3B-034 | Z amplitude matches | ☐ |
| Find Halo Southern | HLR-3B-035 | Symmetry verification | ☐ |
| Richardson guess | HLR-3B-034 | Convergence acceleration | ☐ |
| Orbit family | HLR-3B-035 | Continuation success | ☐ |

**Deliverable:** `ada/tests/hale_tests-periodic_orbits.adb` (expand existing)

### 3.5 Test Traceability (Week 15-16)

**Issues Addressed:** ISS-049

| Task | Deliverable | Status |
|------|-------------|--------|
| Add requirement IDs to all test procedures | Test file comments | ☐ |
| Create test-to-requirement matrix | `docs/certification/test-rtm.md` | ☐ |
| Verify 100% requirement coverage | Coverage report | ☐ |
| Document uncovered requirements | Gap analysis | ☐ |

### 3.6 Tolerance Documentation (Week 16)

**Issues Addressed:** ISS-043, ISS-046, ISS-047, ISS-048, ISS-050, ISS-066, ISS-067, ISS-068

| Tolerance | Location | Documentation | Status |
|-----------|----------|---------------|--------|
| Mu_Vallado | vallado.adb:27 | Add Vallado edition/page | ☐ |
| Position 1e-6 | parallel.adb:19 | Derive from precision | ☐ |
| Reference values | determinism.adb | Add measurement source | ☐ |
| Symplectic 0.01 | periodic_orbits:140 | Tighten to 1e-10 | ☐ |
| Energy 1e-10 | integration:468 | Calculate accumulation | ☐ |
| Default 1e-10 | runner.ads:22 | Document applicability | ☐ |

### Phase 3 Exit Criteria

- [ ] Negative test suite complete with 20+ tests
- [ ] Exception path tests for all 5 exception types
- [ ] Boundary tests for all singular configurations
- [ ] Periodic orbit tests for HLR-3B-033 to HLR-3B-035
- [ ] All test procedures have requirement ID comments
- [ ] All tolerances documented with rationale
- [ ] All Phase 3 issues closed in compliance-issues.csv

---

## Phase 4: Verification & Closure (Weeks 17-19)

### Objective
Complete SPARK verification, coverage analysis, and certification package.

### 4.1 SPARK Verification (Week 17)

**Issues Addressed:** ISS-039, ISS-040, ISS-041, ISS-042

| Task | Package | Deliverable | Status |
|------|---------|-------------|--------|
| Run GNATprove flow analysis | all | Flow report | ☐ |
| Resolve/justify unproven VCs | all | Justification log | ☐ |
| Document SPARK scope | all | Formal methods report | ☐ |
| Document body exemptions | kepler, twobody, elements, lambert | Exemption rationale | ☐ |

### 4.2 Coverage Analysis (Week 17-18)

| Task | Tool | Target | Status |
|------|------|--------|--------|
| Run GNATcoverage statement | GNATcoverage | 100% | ☐ |
| Analyze uncovered statements | Manual | 0 gaps | ☐ |
| Generate coverage report | GNATcoverage | HTML report | ☐ |
| Archive coverage artifacts | CI | Baseline | ☐ |

### 4.3 Magic Number Resolution (Week 18)

**Issues Addressed:** ISS-062, ISS-063, ISS-064, ISS-065

| Magic Number | Location | Resolution | Status |
|--------------|----------|------------|--------|
| Z bounds ±4π² | lambert:148 | Create `Z_Bound_Low/High` constants | ☐ |
| 1.0e10 invalid | lambert:42 | Create `INVALID_FUNCTION_VALUE` | ☐ |
| Hardcoded π | lambert.ads:98 | Use `Two_Pi` from Constants | ☐ |
| 1.0e-15 atan2 | elements:20 | Add comment or constant | ☐ |

### 4.4 Floating-Point Consistency (Week 18)

**Issues Addressed:** ISS-032, ISS-033

| Location | Issue | Resolution | Status |
|----------|-------|------------|--------|
| kepler:37 | E < 0.8 exact | Use threshold constant | ☐ |
| elements:338 | E >= 1.0 exact | Use Parabolic_Threshold | ☐ |

### 4.5 Documentation Finalization (Week 19)

**Issues Addressed:** ISS-061, ISS-070, ISS-071

| Task | Deliverable | Status |
|------|-------------|--------|
| Create formal SRS from contracts | `docs/certification/SRS.md` | ☐ |
| Unify SDS from architecture docs | `docs/certification/SDS.md` | ☐ |
| Create formal SCS | `docs/certification/SCS.md` | ☐ |
| Update compliance checklist | All items COMPLETE | ☐ |
| Generate certification package | `docs/certification/package/` | ☐ |

### 4.6 Final Audit (Week 19)

| Task | Verification | Status |
|------|--------------|--------|
| Review all 71 issues closed | compliance-issues.csv | ☐ |
| Verify RTM 100% coverage | RTM analysis | ☐ |
| Confirm SPARK flow pass | GNATprove report | ☐ |
| Confirm statement coverage | GNATcoverage report | ☐ |
| Package certification evidence | Archive | ☐ |

### Phase 4 Exit Criteria

- [ ] SPARK flow analysis passes
- [ ] 100% statement coverage achieved
- [ ] All magic numbers replaced with constants
- [ ] FP comparisons use consistent thresholds
- [ ] SRS, SDS, SCS documents complete
- [ ] All 71 issues marked CLOSED
- [ ] Certification package archived

---

## Certification Package Contents

Upon completion, the certification package shall contain:

```
docs/certification/package/
├── PSAC.md                    # Plan for Software Aspects of Certification
├── SDP.md                     # Software Development Plan
├── SVP.md                     # Software Verification Plan
├── SCMP.md                    # Software Configuration Management Plan
├── SQAP.md                    # Software Quality Assurance Plan
├── SRS.md                     # Software Requirements Specification
├── SDS.md                     # Software Design Standards
├── SCS.md                     # Software Code Standards
├── RTM.md                     # Requirements Traceability Matrix (expanded)
├── test-rtm.md                # Test-to-Requirement Mapping
├── coverage-report.html       # GNATcoverage Statement Coverage
├── spark-report.html          # GNATprove Flow Analysis
├── compliance-issues.csv      # Issue Tracker (all CLOSED)
├── consultant-assessment.md   # Original Assessment
└── evidence/
    ├── test-results/          # All test execution logs
    ├── spark-proofs/          # GNATprove output
    ├── coverage/              # GNATcoverage artifacts
    └── reviews/               # Code review records
```

---

## Risk Mitigation

### Technical Risks

| Risk | Probability | Mitigation | Contingency |
|------|-------------|------------|-------------|
| SPARK VCs unprovable | Medium | Document exemptions | Add tests for uncovered paths |
| Loop termination unproven | Medium | Add Loop_Variant | Bound maximum iterations |
| Coverage gaps | Low | Systematic test design | Add specific tests |

### Schedule Risks

| Risk | Probability | Mitigation | Contingency |
|------|-------------|------------|-------------|
| Documentation delay | Medium | Use templates | Parallel work streams |
| Tool availability | Low | Early procurement | Manual analysis |
| Resource constraints | Medium | Phased approach | Extend Phase 3 |

---

## Appendix A: Issue Mapping by Phase

### Phase 1 Issues (21)
ISS-014, ISS-015, ISS-016, ISS-017, ISS-018, ISS-019, ISS-020, ISS-021,
ISS-051, ISS-052, ISS-053, ISS-054, ISS-055, ISS-056, ISS-057, ISS-058,
ISS-059, ISS-060, ISS-061, ISS-069, ISS-070, ISS-071

### Phase 2 Issues (25)
ISS-001, ISS-002, ISS-003, ISS-004, ISS-005, ISS-006, ISS-007, ISS-008,
ISS-009, ISS-010, ISS-022, ISS-023, ISS-024, ISS-025, ISS-026, ISS-027,
ISS-028, ISS-029, ISS-030, ISS-031, ISS-034, ISS-035, ISS-036, ISS-037,
ISS-038

### Phase 3 Issues (17)
ISS-011, ISS-012, ISS-013, ISS-043, ISS-044, ISS-045, ISS-046, ISS-047,
ISS-048, ISS-049, ISS-050, ISS-066, ISS-067, ISS-068

### Phase 4 Issues (8)
ISS-032, ISS-033, ISS-039, ISS-040, ISS-041, ISS-042, ISS-062, ISS-063,
ISS-064, ISS-065

---

*Document Version: 1.0*
*Last Updated: 2026-01-06*
*Next Review: End of Phase 1*
