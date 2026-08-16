# Software Verification Plan (SVP)

## HALE Orbital Mechanics Library

**Document Number:** HALE-SVP-001
**Version:** 1.0
**Date:** 2026-01-06
**Classification:** Internal Use
**DO-178C Reference:** Section 11.3

---

## 1. Purpose and Scope

### 1.1 Purpose

This Software Verification Plan (SVP) defines the verification activities, methods, procedures, and environment used to verify that the HALE Orbital Mechanics Library meets its requirements and complies with DO-178C objectives for DAL C.

### 1.2 Scope

This plan covers:
- Verification of high-level requirements
- Verification of low-level requirements
- Verification of software architecture
- Verification of source code
- Testing activities
- Structural coverage analysis
- Formal methods (SPARK)

### 1.3 Verification Objectives

| Objective | Method | Target |
|-----------|--------|--------|
| Requirements complete | Review, Analysis | 100% |
| Design correct | Review, SPARK | 100% |
| Code correct | Review, Test, SPARK | 100% |
| Statement coverage | GNATcoverage | 100% |
| SPARK flow clean | GNATprove | 0 errors |

---

## 2. Referenced Documents

| Document | Description |
|----------|-------------|
| HALE-SDP-001 | Software Development Plan |
| HALE-SCMP-001 | Software Configuration Management Plan |
| HALE-SQAP-001 | Software Quality Assurance Plan |
| HALE-PSAC-001 | Plan for Software Aspects of Certification |
| DO-178C | Software Considerations in Airborne Systems |
| DO-333 | Formal Methods Supplement |

---

## 3. Verification Organization

### 3.1 Roles and Responsibilities

| Role | Responsibilities |
|------|------------------|
| **Verification Lead** | Plan verification activities, assign resources |
| **Test Engineer** | Develop and execute tests |
| **SPARK Engineer** | Perform formal verification |
| **Coverage Analyst** | Analyze and report coverage |
| **Review Coordinator** | Organize and track reviews |

### 3.2 Independence Requirements

Per DO-178C Table A-5:

| Activity | Independence Level | Method |
|----------|-------------------|--------|
| Requirements Review | Independent | Different person |
| Design Review | Independent | Different person |
| Code Review | Independent | Different person |
| Test Development | May be developer | Same person allowed |
| Test Execution | May be developer | Same person allowed |

---

## 4. Verification Methods

### 4.1 Method Overview

| Method | DO-178C Reference | Application |
|--------|-------------------|-------------|
| **Review** | 6.3.1 | Requirements, Design, Code |
| **Analysis** | 6.3.2 | Traceability, Coverage |
| **Test** | 6.4 | Functional verification |
| **Formal Methods** | DO-333 | SPARK proof |

### 4.2 Review Method

#### Types of Reviews

| Review Type | Scope | Participants |
|-------------|-------|--------------|
| Inspection | Line-by-line examination | Developer + Reviewer |
| Walkthrough | Guided presentation | Author + Team |
| Desk Check | Self-review | Developer |

#### Review Checklists

See SQAP Section 4.2 for review checklists.

### 4.3 Analysis Method

| Analysis Type | Purpose | Tool |
|---------------|---------|------|
| Traceability | Verify bidirectional trace | Manual/RTM |
| Coverage | Measure test completeness | GNATcoverage |
| Data Flow | Verify data dependencies | GNATprove |
| Control Flow | Verify control paths | GNATprove |

### 4.4 Test Method

| Test Level | Scope | Approach |
|------------|-------|----------|
| Unit | Individual functions | White-box |
| Integration | Package interactions | Black-box |
| Validation | Textbook values | Oracle-based |
| Boundary | Edge cases | Equivalence partitioning |

### 4.5 Formal Methods (SPARK)

| SPARK Level | Verification | Evidence |
|-------------|--------------|----------|
| Level 1 | Flow analysis | No uninitialized reads |
| Level 2 | Absence of RTE | No runtime errors |
| Level 3 | Functional proofs | Postconditions hold |

---

## 5. Verification Activities

### 5.1 Requirements Verification (Table A-3)

#### A-3.1: High-Level Requirements are Accurate and Consistent

| Verification | Method | Evidence |
|--------------|--------|----------|
| Accuracy | Review against source (Hale/Vallado) | Review record |
| Consistency | Cross-check RTM | RTM |
| Completeness | Traceability analysis | RTM |

#### A-3.2: High-Level Requirements are Verifiable

| Verification | Method | Evidence |
|--------------|--------|----------|
| Testability | Each HLR has test procedure | RTM Test column |
| Measurability | Tolerances specified | Contract definitions |

#### A-3.3: High-Level Requirements Conform to Standards

| Verification | Method | Evidence |
|--------------|--------|----------|
| Format compliance | Review | Review record |
| Reference to standards | Trace to Hale/Vallado | RTM Source column |

#### A-3.4: High-Level Requirements are Traceable

| Verification | Method | Evidence |
|--------------|--------|----------|
| Trace to source | RTM analysis | RTM |
| Trace to LLR | RTM analysis | RTM |

#### A-3.5: Algorithms are Accurate

| Verification | Method | Evidence |
|--------------|--------|----------|
| Algorithm correctness | Vallado validation tests | Test results |
| Numerical accuracy | Tolerance verification | Test results |

### 5.2 Low-Level Requirements Verification (Table A-4)

#### A-4.1: Low-Level Requirements Comply with HLRs

| Verification | Method | Evidence |
|--------------|--------|----------|
| Traceability | RTM analysis | RTM |
| Completeness | All HLRs have LLRs | RTM |

#### A-4.2: Low-Level Requirements are Accurate

| Verification | Method | Evidence |
|--------------|--------|----------|
| Contract correctness | SPARK proof | GNATprove output |
| Precondition complete | Review | Review record |
| Postcondition meaningful | Review | Review record |

#### A-4.3: Low-Level Requirements are Verifiable

| Verification | Method | Evidence |
|--------------|--------|----------|
| Contracts executable | `-gnata` testing | Test results |
| SPARK provable | GNATprove | Proof output |

### 5.3 Source Code Verification (Table A-5)

#### A-5.1: Source Code Complies with LLRs

| Verification | Method | Evidence |
|--------------|--------|----------|
| Contract satisfaction | SPARK proof | GNATprove output |
| Algorithm implementation | Code review | Review record |

#### A-5.2: Source Code is Verifiable

| Verification | Method | Evidence |
|--------------|--------|----------|
| Testable | Unit tests exist | Test files |
| Provable | SPARK_Mode On | GNATprove |

#### A-5.3: Source Code Conforms to Standards

| Verification | Method | Evidence |
|--------------|--------|----------|
| Style compliance | `-gnatyg` | Build log |
| Warning free | `-gnatwa` | Build log |
| SPARK clean | GNATprove | Proof output |

#### A-5.4: Source Code is Traceable

| Verification | Method | Evidence |
|--------------|--------|----------|
| To requirements | RTM | RTM |
| To design | Architecture docs | Design docs |

#### A-5.5: Source Code is Accurate

| Verification | Method | Evidence |
|--------------|--------|----------|
| Functional correctness | Unit tests | Test results |
| Edge case handling | Boundary tests | Test results |
| SPARK proof | GNATprove | Proof output |

#### A-5.6: Executable Object Code is Accurate

| Verification | Method | Evidence |
|--------------|--------|----------|
| Test execution | Integration tests | Test results |
| Cross-platform | CI on Linux/Windows | CI logs |

---

## 6. Testing Process

### 6.1 Test Categories

| Category | Purpose | Count |
|----------|---------|-------|
| Vallado Validation | Algorithm correctness | ~50 tests |
| Integration | Package interaction | ~30 tests |
| Edge Cases | Boundary conditions | ~40 tests |
| Parallel | Parallel execution | ~15 tests |
| Determinism | Reproducibility | ~10 tests |
| Periodic Orbits | Three-body dynamics | ~10 tests |
| **Negative** | Invalid inputs | TBD (Phase 3) |
| **Exception** | Error paths | TBD (Phase 3) |

### 6.2 Test Procedures

#### Unit Test Structure

```ada
procedure Test_Feature is
   -- Setup
   Input : constant Input_Type := ...;
   Expected : constant Output_Type := ...;
   Tolerance : constant Real := 1.0e-10;

   -- Execute
   Result : constant Output_Type := Feature(Input);
begin
   -- Verify
   Assert(abs(Result - Expected) < Tolerance,
          "Feature failed: expected " & Expected'Image &
          " got " & Result'Image);
end Test_Feature;
```

#### Test Naming Convention

```
Test_<Package>_<Function>_<Scenario>
```

Example: `Test_Kepler_Solve_Elliptic_HighEccentricity`

### 6.3 Test Data

| Source | Purpose | Traceability |
|--------|---------|--------------|
| Vallado tables | Reference values | Book/page/table |
| Analytical | Known solutions | Mathematical derivation |
| Boundary | Edge cases | Requirement bounds |
| Random | Robustness | Monte Carlo seeds |

### 6.4 Test Execution

```bash
# Build tests
gprbuild -P ada/tests/hale_tests.gpr -XBUILD_MODE=debug

# Run tests
./ada/tests/bin/hale_tests

# Run with assertions
./ada/tests/bin/hale_tests --assertions

# Generate coverage
gnatcov run ./ada/tests/bin/hale_tests
gnatcov coverage --annotate=html
```

### 6.5 Test Reporting

Test report includes:
- Test case ID
- Requirement traced
- Input data
- Expected result
- Actual result
- Pass/Fail status
- Execution time

---

## 7. Structural Coverage Analysis

### 7.1 Coverage Objectives (DAL C)

| Coverage Type | Target | DO-178C Reference |
|---------------|--------|-------------------|
| Statement | 100% | Table A-7, Objective 5 |

Note: Decision and MC/DC coverage required for DAL B and A respectively.

### 7.2 Coverage Tool

| Tool | Version | Configuration |
|------|---------|---------------|
| GNATcoverage | 24.x | Statement level |

### 7.3 Coverage Process

1. Build with coverage instrumentation
2. Execute test suite
3. Collect coverage data
4. Generate coverage report
5. Analyze uncovered code
6. Add tests or document justification

### 7.4 Coverage Analysis

For uncovered statements:

| Category | Action |
|----------|--------|
| Dead code | Remove or document |
| Defensive code | Document as safety margin |
| Error handlers | Add negative tests |
| Edge cases | Add boundary tests |

### 7.5 Coverage Reporting

```
Coverage Report: HALE Orbital Mechanics Library
Date: YYYY-MM-DD
Tool: GNATcoverage X.Y

Package           | Statements | Covered | Uncovered | %
------------------|------------|---------|-----------|----
hale_orbital      |         10 |      10 |         0 | 100%
hale_orbital-types|          0 |       0 |         0 | N/A
hale_orbital-kepler|        150 |     148 |         2 |  99%
...
TOTAL             |       1500 |    1490 |        10 |  99%

Uncovered Analysis:
- kepler.adb:47 - Defensive check, never triggered
- lambert.adb:203 - Error path, add negative test
```

---

## 8. Formal Methods (SPARK)

### 8.1 SPARK Strategy

| Package | Spec Mode | Body Mode | Proof Level |
|---------|-----------|-----------|-------------|
| Types | ON | N/A | N/A |
| Constants | ON | N/A | N/A |
| Vectors | ON | Off | Flow |
| Matrices | ON | Off | Flow |
| Twobody | ON | Off | Flow |
| Elements | ON | Off | Flow |
| Kepler | ON | Off | Flow |
| Stumpff | ON | Off | Flow |
| Lambert | ON | Off | Flow |
| Maneuvers | ON | Off | Flow |
| Threebody | ON | Off | Flow |
| Interplanetary | ON | Off | Flow |

### 8.2 SPARK Objectives

| Objective | Evidence |
|-----------|----------|
| No uninitialized reads | GNATprove flow output |
| No ineffective statements | GNATprove flow output |
| Global/Depends correct | GNATprove flow output |
| Preconditions sufficient | GNATprove proof output |
| Postconditions hold | GNATprove proof output (partial) |

### 8.3 SPARK Execution

```bash
# Flow analysis only
gnatprove -P ada/hale_orbital.gpr --mode=flow

# Flow + proof
gnatprove -P ada/hale_orbital.gpr --level=2

# Full proof with manual review
gnatprove -P ada/hale_orbital.gpr --level=4 --report=all
```

### 8.4 Unproven VC Handling

For verification conditions that cannot be proven:

1. **Analyze**: Understand why proof fails
2. **Strengthen**: Add loop invariants or assertions
3. **Justify**: Document mathematical justification
4. **Test**: Add specific test for the case
5. **Document**: Record in verification report

---

## 9. Verification Environment

### 9.1 Hardware

| Component | Specification |
|-----------|---------------|
| CPU | x86_64, 4+ cores |
| RAM | 16+ GB |
| Storage | SSD, 50+ GB |
| OS | Linux (primary), Windows (secondary) |

### 9.2 Software Tools

| Tool | Purpose | Version |
|------|---------|---------|
| GNAT Pro | Compilation | 24.x |
| GNATprove | SPARK proof | 24.x |
| GNATcoverage | Coverage | 24.x |
| Git | Version control | 2.x |
| GitHub Actions | CI/CD | N/A |

### 9.3 CI Pipeline

```yaml
verification:
  steps:
    - build-debug
    - run-tests
    - spark-flow-analysis
    - coverage-analysis
    - generate-reports
    - archive-evidence
```

---

## 10. Verification Reporting

### 10.1 Test Results Report

| Content | Format |
|---------|--------|
| Test summary | Pass/Fail counts |
| Test details | Individual results |
| Failures | Root cause analysis |
| Coverage | GNATcoverage output |

### 10.2 SPARK Report

| Content | Format |
|---------|--------|
| Flow summary | Error/warning counts |
| Proof summary | Proven/unproven VCs |
| Unproven analysis | Justification |

### 10.3 Verification Summary Report

Final verification report includes:
- Requirements coverage matrix
- Test results summary
- Coverage analysis summary
- SPARK verification summary
- Open issues
- Conclusion

---

## 11. Verification Completion Criteria

### 11.1 Test Completion

- [ ] All test procedures executed
- [ ] All tests pass
- [ ] All failures analyzed and resolved
- [ ] Test reports generated

### 11.2 Coverage Completion

- [ ] 100% statement coverage achieved
- [ ] Uncovered code analyzed
- [ ] Coverage report generated

### 11.3 SPARK Completion

- [ ] Flow analysis clean (0 errors)
- [ ] Proof analysis complete
- [ ] Unproven VCs justified
- [ ] SPARK report generated

### 11.4 Review Completion

- [ ] All reviews conducted
- [ ] All findings resolved
- [ ] Review records archived

---

## 12. Problem Reporting

Verification problems reported per SQAP Section 5.

| Severity | Example | Action |
|----------|---------|--------|
| Critical | Test reveals safety issue | Stop, analyze, fix |
| High | Coverage gap | Add tests |
| Medium | SPARK warning | Analyze, fix or justify |
| Low | Documentation issue | Fix in next iteration |

---

## Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-01-06 | | Initial release |

---

## Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Verification Lead | | | |
| QA Manager | | | |
| Project Manager | | | |
