# DO-178C Level B Certification Roadmap

**Document Version:** 1.0
**Created:** 2026-01-06
**Target:** DAL B (Hazardous/Severe-Major Failure Condition)
**Baseline:** Level C Certification (completed 2026-01-06)
**Prerequisite:** All Level C requirements satisfied

---

## Overview

This roadmap provides a phased approach to upgrading the HALE Orbital Mechanics Library from DO-178C Level C to Level B. Level B adds significant verification rigor, particularly in structural coverage analysis and independence requirements.

### Key Differences: Level C → Level B

| Aspect | Level C | Level B |
|--------|---------|---------|
| Structural Coverage | Statement Coverage | Statement + Decision Coverage |
| Review Independence | Same team allowed | Different person required |
| Test Independence | Developer can test | Independent tester preferred |
| Tool Qualification | TQL-5 | TQL-4 |
| Code Review | Recommended | Required with checklist |
| Requirements Review | Required | Required with independence |

### Timeline Summary

```
Phase 1: Coverage Infrastructure       [Weeks 1-4]
Phase 2: Decision Coverage Testing     [Weeks 5-10]
Phase 3: Independence & Reviews        [Weeks 11-14]
Phase 4: Tool Qualification            [Weeks 15-17]
Phase 5: Verification & Closure        [Weeks 18-20]
```

### Success Criteria

| Metric | Level C | Level B Target |
|--------|---------|----------------|
| Statement Coverage | 100% | 100% |
| Decision Coverage | N/A | 100% |
| MC/DC Coverage | N/A | Not required (Level A) |
| Independent Reviews | Recommended | 100% |
| Tool Qualification | TQL-5 | TQL-4 |
| SPARK Proof Level | Bronze | Silver minimum |

---

## Phase 1: Coverage Infrastructure (Weeks 1-4)

### Objective
Establish tooling and processes for decision coverage measurement.

### 1.1 GNATcoverage Configuration (Week 1)

**New Capability:** Decision coverage instrumentation

| Task | Deliverable | Status |
|------|-------------|--------|
| Upgrade GNATcoverage to latest | Installation verified | ☐ |
| Configure decision coverage mode | `--level=stmt+decision` | ☐ |
| Create coverage project file | `coverage.gpr` | ☐ |
| Document coverage workflow | `coverage-guide.md` | ☐ |

**Configuration Template:**
```ada
package Coverage is
   for Switches use ("--level=stmt+decision",
                     "--annotate=xcov+",
                     "--output-dir=coverage");
end Coverage;
```

### 1.2 Test Harness Enhancement (Week 1-2)

**New Capability:** Coverage-aware test execution

| Task | Deliverable | Status |
|------|-------------|--------|
| Create coverage test driver | `test_driver_coverage.adb` | ☐ |
| Add coverage merge script | `merge_coverage.sh` | ☐ |
| Configure CI for coverage | `.github/workflows/coverage.yml` | ☐ |
| Create coverage baseline | `baseline-coverage.xml` | ☐ |

### 1.3 Coverage Gap Analysis (Week 2-3)

**Initial Assessment:** Identify decision coverage gaps

| Package | Est. Stmt Coverage | Est. Decision Coverage | Gap |
|---------|-------------------|----------------------|-----|
| Vectors | 100% | ~95% | Low |
| Matrices | 100% | ~90% | Low |
| Elements | 100% | ~80% | Medium |
| Kepler | 100% | ~75% | Medium |
| Lambert | 100% | ~70% | High |
| Propagation | 100% | ~85% | Medium |
| Threebody | 100% | ~70% | High |

### 1.4 Decision Point Inventory (Week 3-4)

**Catalog all decision points for targeted testing:**

| Category | Example | Test Strategy |
|----------|---------|---------------|
| Boolean parameters | `Long_Way : Boolean` | True/False cases |
| Threshold comparisons | `E < 0.8` | Boundary tests |
| Convergence checks | `abs(F) < Tolerance` | Edge cases |
| Sign checks | `Cross_Z >= 0.0` | Positive/negative/zero |
| Range checks | `E >= 0.0 and E < 1.0` | Boundary + interior |

**Deliverable:** `decision-point-inventory.csv`

### Phase 1 Exit Criteria

- [ ] GNATcoverage producing decision coverage reports
- [ ] Test harness runs all tests with coverage
- [ ] Initial decision coverage baseline established
- [ ] Gap analysis complete with prioritized list
- [ ] Decision point inventory catalogued

---

## Phase 2: Decision Coverage Testing (Weeks 5-10)

### Objective
Achieve 100% decision coverage through targeted test case development.

### 2.1 Boolean Parameter Coverage (Week 5)

**Target:** All Boolean parameters exercised both ways

| Function | Parameter | True Test | False Test | Status |
|----------|-----------|-----------|------------|--------|
| `Solve_Lambert` | `Long_Way` | ☐ | ☐ | ☐ |
| `Transfer_Angle` | `Long_Way` | ☐ | ☐ | ☐ |
| `Minimum_Energy_Tof` | `Long_Way` | ☐ | ☐ | ☐ |
| `Solve_Lambert_Multi` | `Long_Way` | ☐ | ☐ | ☐ |
| `Find_Halo_Orbit` | `Family` | North | South | ☐ |

**Deliverable:** `hale_tests-boolean_coverage.ads/adb`

### 2.2 Conditional Branch Coverage (Week 5-6)

**Target:** All if/elsif/else branches executed

| Location | Condition | True Path | False Path | Status |
|----------|-----------|-----------|------------|--------|
| kepler:37 | `E < High_Eccentricity_Threshold` | ☐ | ☐ | ☐ |
| elements:338 | `E > 1.0 - Parabolic_Threshold` | ☐ | ☐ | ☐ |
| lambert:41 | `Y < 0.0` | ☐ | ☐ | ☐ |
| lambert:176 | `Y < 0.0` (inner) | ☐ | ☐ | ☐ |
| lambert:178 | `Z > 0.0` | ☐ | ☐ | ☐ |
| lambert:201 | `F_Z < 0.0` | ☐ | ☐ | ☐ |

**Deliverable:** `hale_tests-branch_coverage.ads/adb`

### 2.3 Loop Exit Condition Coverage (Week 6-7)

**Target:** All loop exits triggered

| Location | Exit Condition | Normal Exit | Max Iter Exit | Status |
|----------|---------------|-------------|---------------|--------|
| kepler (elliptic) | Convergence | ☐ | ☐ | ☐ |
| kepler (hyperbolic) | Convergence | ☐ | ☐ | ☐ |
| kepler (universal) | Convergence | ☐ | ☐ | ☐ |
| lambert | Convergence | ☐ | ☐ | ☐ |
| threebody (periodic) | Periodicity | ☐ | ☐ | ☐ |

**Test Cases for Max Iteration Exit:**
- Extremely tight tolerance (1e-20)
- Max_Iter = 1 or 2
- Pathological inputs (high eccentricity near 1.0)

**Deliverable:** `hale_tests-loop_coverage.ads/adb`

### 2.4 Exception Path Coverage (Week 7-8)

**Target:** All exception raise points triggered

| Exception | Location | Trigger Condition | Test | Status |
|-----------|----------|-------------------|------|--------|
| `Convergence_Error` | kepler | Max iter exceeded | ☐ | ☐ |
| `Invalid_Orbit` | elements | Inconsistent elements | ☐ | ☐ |
| `Singularity_Error` | vectors | Normalize zero | ☐ | ☐ |
| `Physical_Error` | twobody | Negative radius | ☐ | ☐ |

**Note:** Already partially covered in Phase 3 (Level C), extend for completeness.

**Deliverable:** `hale_tests-exception_coverage.ads/adb` (extended)

### 2.5 Compound Decision Coverage (Week 8-9)

**Target:** Each term in compound decisions evaluated both ways

| Location | Decision | Term 1 | Term 2 | Term 3 | Status |
|----------|----------|--------|--------|--------|--------|
| kepler Pre | `E >= 0.0 and E < 1.0` | T/F | T/F | N/A | ☐ |
| lambert Pre | `Mag(R1) > 0 and Mag(R2) > 0 and TOF > 0` | T/F | T/F | T/F | ☐ |
| twobody Pre | `Real(R) > 0.0 and Real(Mu) > 0.0` | T/F | T/F | N/A | ☐ |

**Deliverable:** `hale_tests-compound_decisions.ads/adb`

### 2.6 Short-Circuit Evaluation Coverage (Week 9-10)

**Target:** Verify short-circuit behavior

For `A and then B`:
- Test case where A is False (B not evaluated)
- Test case where A is True, B is True
- Test case where A is True, B is False

For `A or else B`:
- Test case where A is True (B not evaluated)
- Test case where A is False, B is True
- Test case where A is False, B is False

**Deliverable:** `hale_tests-shortcircuit.ads/adb`

### 2.7 Coverage Verification (Week 10)

| Task | Tool | Target | Status |
|------|------|--------|--------|
| Run full test suite with coverage | GNATcoverage | 100% DC | ☐ |
| Generate coverage report | GNATcoverage | HTML | ☐ |
| Analyze uncovered decisions | Manual | 0 gaps | ☐ |
| Document justifications | Coverage report | All gaps justified | ☐ |

### Phase 2 Exit Criteria

- [ ] 100% statement coverage maintained
- [ ] 100% decision coverage achieved
- [ ] All Boolean parameters exercised both ways
- [ ] All loop exits triggered
- [ ] All exception paths executed
- [ ] Coverage report archived

---

## Phase 3: Independence & Reviews (Weeks 11-14)

### Objective
Establish independent verification processes required for Level B.

### 3.1 Review Independence Structure (Week 11)

**Level B Requirement:** Reviews performed by person other than developer

| Role | Responsibility | Independence |
|------|---------------|--------------|
| Developer | Write code | N/A |
| Code Reviewer | Review code changes | Different person |
| Test Reviewer | Review test cases | Different person |
| V&V Lead | Approve verification | Not developer |

**Process Document:** `docs/certification/review-process.md`

### 3.2 Code Review Checklists (Week 11-12)

**Checklist Categories:**

| Category | Items | Reference |
|----------|-------|-----------|
| Coding Standards | 15 items | SCS compliance |
| SPARK Contracts | 10 items | Contract completeness |
| Numeric Safety | 8 items | Division guards, overflow |
| Error Handling | 6 items | Exception coverage |
| Traceability | 5 items | RTM mapping |

**Deliverable:** `docs/certification/code-review-checklist.md`

### 3.3 Requirements Review (Week 12)

| Requirement Set | Reviewer | Status |
|-----------------|----------|--------|
| HLR-1A (Two-Body) | Independent | ☐ |
| HLR-1B (Anomaly) | Independent | ☐ |
| HLR-2A (Lambert) | Independent | ☐ |
| HLR-2B (Propagation) | Independent | ☐ |
| HLR-3B (Three-Body) | Independent | ☐ |
| NFR-* (Non-Functional) | Independent | ☐ |

**Deliverable:** Signed review records

### 3.4 Test Review (Week 12-13)

| Test Suite | Tests | Reviewer | Status |
|------------|-------|----------|--------|
| vallado | 25 | Independent | ☐ |
| edge_cases | 60 | Independent | ☐ |
| negative | 32 | Independent | ☐ |
| exceptions | 24 | Independent | ☐ |
| boundaries | 30 | Independent | ☐ |
| periodic_orbits | 18 | Independent | ☐ |
| decision_coverage | TBD | Independent | ☐ |

**Review Criteria:**
- Tests trace to requirements
- Expected results documented
- Tolerances justified
- Pass/fail criteria clear

### 3.5 Design Review (Week 13-14)

| Document | Reviewer | Status |
|----------|----------|--------|
| SRS | Independent | ☐ |
| SDS | Independent | ☐ |
| SCS | Independent | ☐ |
| RTM | Independent | ☐ |

**Deliverable:** Review records with findings and resolutions

### 3.6 Problem Report Process (Week 14)

| Element | Description | Status |
|---------|-------------|--------|
| PR template | Standard form | ☐ |
| Classification | Severity levels | ☐ |
| Resolution tracking | GitHub issues | ☐ |
| Closure criteria | Verification required | ☐ |

**Deliverable:** `docs/certification/problem-report-process.md`

### Phase 3 Exit Criteria

- [ ] Review independence documented
- [ ] Code review checklist complete
- [ ] All requirements independently reviewed
- [ ] All tests independently reviewed
- [ ] Design documents reviewed
- [ ] Problem report process established

---

## Phase 4: Tool Qualification (Weeks 15-17)

### Objective
Qualify verification tools to TQL-4 (Level B requirement).

### 4.1 Tool Inventory (Week 15)

| Tool | Version | Use | Current TQL | Target TQL |
|------|---------|-----|-------------|------------|
| GNAT | 12.2+ | Compilation | TQL-5 | TQL-4 |
| GNATprove | 23.0+ | SPARK proof | TQL-5 | TQL-4 |
| GNATcoverage | 23.0+ | Coverage | TQL-5 | TQL-4 |
| AUnit | 21.0+ | Test framework | TQL-5 | TQL-4 |

### 4.2 Criteria 1-3 Verification (Week 15-16)

**Criteria 1:** Tool operational requirements documented
**Criteria 2:** Tool installed correctly
**Criteria 3:** Tool produces expected output

| Tool | Criteria 1 | Criteria 2 | Criteria 3 | Status |
|------|------------|------------|------------|--------|
| GNAT | ☐ | ☐ | ☐ | ☐ |
| GNATprove | ☐ | ☐ | ☐ | ☐ |
| GNATcoverage | ☐ | ☐ | ☐ | ☐ |

**Test Cases for Criteria 3:**
- Known-good inputs produce expected outputs
- Known-bad inputs detected correctly
- Edge cases handled properly

### 4.3 Tool Qualification Data (Week 16-17)

**For each tool:**

| Deliverable | Content | Status |
|-------------|---------|--------|
| Tool Qualification Plan | Scope, criteria | ☐ |
| Operational requirements | How tool is used | ☐ |
| Verification cases | Test inputs/outputs | ☐ |
| Qualification report | Evidence of compliance | ☐ |

**Location:** `docs/certification/tool-qualification/`

### 4.4 Alternative Tool Consideration (Week 17)

If TQL-4 too costly, evaluate:

| Alternative | Approach | Effort |
|-------------|----------|--------|
| Manual verification | Reduce tool reliance | High |
| Tool output review | Independent check of results | Medium |
| Redundant tools | Cross-check with second tool | Medium |

### Phase 4 Exit Criteria

- [ ] Tool inventory complete
- [ ] Criteria 1-3 verified for all tools
- [ ] Tool qualification plans written
- [ ] Qualification evidence collected
- [ ] TQL-4 achieved or alternatives documented

---

## Phase 5: Verification & Closure (Weeks 18-20)

### Objective
Complete Level B verification activities and certification package.

### 5.1 SPARK Proof Enhancement (Week 18)

**Upgrade from Bronze to Silver:**

| Package | Current | Target | Status |
|---------|---------|--------|--------|
| Vectors | Gold | Gold | ✓ |
| Matrices | Silver | Silver | ✓ |
| Types | Bronze | Bronze | ✓ |
| Constants | Bronze | Bronze | ✓ |
| Elements | Bronze | Silver | ☐ |
| Kepler | Bronze | Silver | ☐ |
| Twobody | Bronze | Silver | ☐ |

**Silver Level Requirements:**
- All runtime checks proven absent
- All preconditions satisfiable
- All postconditions proven

### 5.2 Traceability Verification (Week 18-19)

| Trace | Direction | Coverage | Status |
|-------|-----------|----------|--------|
| System → HLR | Forward | 100% | ☐ |
| HLR → Design | Forward | 100% | ☐ |
| HLR → Test | Forward | 100% | ☐ |
| Test → HLR | Backward | 100% | ☐ |
| Code → HLR | Backward | 100% | ☐ |

### 5.3 Coverage Analysis Finalization (Week 19)

| Metric | Target | Achieved | Status |
|--------|--------|----------|--------|
| Statement Coverage | 100% | | ☐ |
| Decision Coverage | 100% | | ☐ |
| Requirements Coverage | 100% | | ☐ |
| SPARK Proof Coverage | 90%+ | | ☐ |

**Uncovered Code Justification:**
Any uncovered code must have documented justification:
- Dead code analysis
- Defensive code rationale
- Exception handler coverage

### 5.4 Certification Package Assembly (Week 19-20)

```
docs/certification/level-b-package/
├── PSAC-B.md                    # Updated for Level B
├── SDP-B.md                     # Updated standards
├── SVP-B.md                     # Decision coverage added
├── SCMP-B.md                    # Review independence
├── SQAP-B.md                    # Updated QA requirements
├── SRS.md                       # From Level C
├── SDS.md                       # From Level C
├── SCS.md                       # From Level C
├── RTM-B.md                     # Updated traceability
├── coverage-report/
│   ├── statement-coverage.html
│   └── decision-coverage.html
├── spark-report/
│   └── silver-proof.html
├── reviews/
│   ├── code-reviews/
│   ├── test-reviews/
│   └── design-reviews/
├── tool-qualification/
│   ├── gnat-tql4.pdf
│   ├── gnatprove-tql4.pdf
│   └── gnatcoverage-tql4.pdf
└── evidence/
    ├── test-results/
    └── problem-reports/
```

### 5.5 Final Audit (Week 20)

| Task | Verification | Status |
|------|--------------|--------|
| Level C compliance maintained | Checklist | ☐ |
| Decision coverage 100% | Report | ☐ |
| Independent reviews complete | Records | ☐ |
| Tool qualification complete | Reports | ☐ |
| Traceability verified | RTM analysis | ☐ |
| Certification package complete | Audit | ☐ |

### Phase 5 Exit Criteria

- [ ] SPARK Silver achieved for core packages
- [ ] 100% decision coverage verified
- [ ] All traceability verified bidirectionally
- [ ] Certification package assembled
- [ ] Final audit passed
- [ ] Level B declaration ready

---

## Risk Mitigation

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Decision coverage gaps | Medium | High | Targeted test development |
| Tool qualification cost | High | Medium | Alternative approaches |
| SPARK proof complexity | Medium | Medium | Justified exemptions |
| Independence resources | Medium | High | External reviewer contracts |

### Schedule Risks

| Risk | Probability | Mitigation |
|------|-------------|------------|
| Coverage gap remediation | Medium | Early gap analysis |
| Review bottleneck | High | Parallel review streams |
| Tool issues | Low | Fallback procedures |

---

## Resource Requirements

### Personnel

| Role | Effort | Notes |
|------|--------|-------|
| Developer | 0.5 FTE | Test development |
| Independent Reviewer | 0.25 FTE | Reviews |
| V&V Engineer | 0.25 FTE | Coverage, proof |
| Tool Qualification | 0.1 FTE | TQL-4 evidence |

### Tools

| Tool | License | Status |
|------|---------|--------|
| GNAT Pro | Required | TBD |
| GNATprove Pro | Required | TBD |
| GNATcoverage Pro | Required | TBD |

---

## Appendix A: Level B Additions Summary

| Category | Level C | Level B Addition |
|----------|---------|------------------|
| Coverage | Statement | + Decision |
| Reviews | Recommended | + Independence |
| Tools | TQL-5 | TQL-4 |
| SPARK | Bronze | Silver |
| Traceability | Forward | + Backward |
| Problem Reports | Informal | Formal process |

---

*Document Version: 1.0*
*Last Updated: 2026-01-06*
*Next Review: End of Phase 1*
