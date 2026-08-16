# Plan for Software Aspects of Certification (PSAC)

## HALE Orbital Mechanics Library

**Document Number:** HALE-PSAC-001
**Version:** 1.0
**Date:** 2026-01-06
**Classification:** Internal Use
**DO-178C Reference:** Section 11.1

---

## 1. System Overview

### 1.1 System Description

The HALE Orbital Mechanics Library is a reusable software library providing orbital mechanics computations for space mission applications. It implements algorithms from F.J. Hale's "Introduction to Space Flight" with additional validation against D.A. Vallado's reference implementations.

### 1.2 System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Host System                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │          Application Software                    │   │
│  │  ┌───────────────────────────────────────────┐  │   │
│  │  │     HALE Orbital Mechanics Library        │  │   │
│  │  │  ┌─────────┐ ┌─────────┐ ┌─────────────┐ │  │   │
│  │  │  │ Twobody │ │ Kepler  │ │ Maneuvers   │ │  │   │
│  │  │  │ Elements│ │ Lambert │ │ Propagation │ │  │   │
│  │  │  │ Vectors │ │ Matrices│ │ Threebody   │ │  │   │
│  │  │  └─────────┘ └─────────┘ └─────────────┘ │  │   │
│  │  └───────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Ada Runtime / GNAT                  │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 1.3 Software Functions

| Package | Function | Safety Relevance |
|---------|----------|------------------|
| Twobody | Two-body orbital dynamics | Trajectory prediction |
| Elements | Orbital element conversions | State representation |
| Kepler | Kepler equation solvers | Orbit propagation |
| Lambert | Lambert problem solver | Transfer orbit design |
| Maneuvers | Delta-V calculations | Maneuver planning |
| Propagation | Numerical integration | Trajectory prediction |
| Threebody | Three-body dynamics | Lagrange point missions |
| Interplanetary | Planetary transfer | Mission design |

---

## 2. Software Overview

### 2.1 Software Identification

| Attribute | Value |
|-----------|-------|
| Name | HALE Orbital Mechanics Library |
| Version | 0.1.0 |
| Part Number | HALE-OML-001 |
| Language | Ada 2012 / SPARK 2014 |

### 2.2 Software Features

| Feature | Description |
|---------|-------------|
| Modular Design | 14 packages with clear interfaces |
| SPARK Annotations | Formal verification capability |
| Dimensional Types | Compile-time unit safety |
| Deterministic Mode | Cross-platform reproducibility |
| Comprehensive Tests | 150+ test procedures |

### 2.3 Software Partitioning

The library operates within the application partition. No separate partitioning is required as it:
- Does not have direct hardware access
- Does not perform safety-critical control functions directly
- Provides computational services only

---

## 3. Certification Considerations

### 3.1 Design Assurance Level (DAL)

| Aspect | Determination |
|--------|---------------|
| **Target DAL** | **C (Major)** |
| Rationale | Computational errors could lead to mission failure but not loss of life |
| Upgrade Path | Architecture supports DAL B/A with additional verification |

### 3.2 Failure Condition Analysis

| Failure Mode | Effect | Severity |
|--------------|--------|----------|
| Incorrect trajectory prediction | Mission deviation | Major |
| Incorrect maneuver calculation | Propellant waste, mission impact | Major |
| Non-convergence of solver | Computation failure, detected | Minor |
| Numerical overflow | Erroneous result | Major |

### 3.3 Software Level Justification

The library is classified as DAL C based on:

1. **No direct control**: Library provides computations only
2. **Detectable failures**: Solver convergence is checked
3. **Mission-critical, not life-critical**: Space mission context
4. **Defense in depth**: Host system provides additional verification

---

## 4. Software Life Cycle

### 4.1 Life Cycle Model

Iterative development with formal phase gates, as defined in SDP.

### 4.2 Life Cycle Data

| Data Item | Document |
|-----------|----------|
| Plans | SDP, SVP, SCMP, SQAP, PSAC |
| Requirements | RTM |
| Design | Architecture docs, DEC-* |
| Source Code | `ada/src/` |
| Test Cases | `ada/tests/` |
| Test Results | CI artifacts |
| Coverage | GNATcoverage reports |
| Proofs | GNATprove output |

### 4.3 Transition Criteria

See SDP Section 10 for phase transition criteria.

---

## 5. Software Development Environment

### 5.1 Development Tools

| Tool | Version | Qualification |
|------|---------|---------------|
| GNAT Pro | 24.x | TQL-1 per DO-330 |
| GNATprove | 24.x | TQL-1 per DO-330 |
| GNATcoverage | 24.x | TQL-1 per DO-330 |
| gprbuild | 24.x | TQL-3 |
| Git | 2.x | N/A |

### 5.2 Tool Qualification

AdaCore provides pre-qualified tool suites. Qualification evidence:
- Tool Qualification Plan
- Tool Operational Requirements
- Tool Accomplishment Summary

### 5.3 Development Standards

| Standard | Reference |
|----------|-----------|
| Ada 2012 | ARM 2012 |
| SPARK 2014 | SPARK Reference Manual |
| Coding | SDP Section 4 |

---

## 6. Software Verification Environment

### 6.1 Verification Tools

| Tool | Purpose |
|------|---------|
| GNATprove | SPARK formal verification |
| GNATcoverage | Structural coverage |
| AUnit | Test framework |
| GitHub Actions | CI/CD |

### 6.2 Verification Methods

| Method | Application |
|--------|-------------|
| Review | Requirements, Design, Code |
| Analysis | Traceability, Coverage |
| Test | Functional verification |
| Formal Methods | SPARK proof (DO-333) |

---

## 7. Certification Liaison

### 7.1 Means of Compliance

| DO-178C Objective | Means |
|-------------------|-------|
| Table A-1 (Planning) | Plans reviewed and approved |
| Table A-2 (Development) | Iterative with reviews |
| Table A-3 (HLR Verification) | Review + Traceability |
| Table A-4 (LLR Verification) | Review + SPARK |
| Table A-5 (Code Verification) | Review + Test + SPARK |
| Table A-6 (Testing) | Vallado validation + unit tests |
| Table A-7 (Coverage) | GNATcoverage statement |

### 7.2 Formal Methods Credit (DO-333)

SPARK formal methods provide credit for:

| Activity | Traditional | With SPARK |
|----------|-------------|------------|
| Flow analysis | Code review | GNATprove |
| Data coupling | Review | Global/Depends |
| Control coupling | Review | GNATprove |
| Robustness | Testing | Preconditions |

### 7.3 Deviations

No deviations from DO-178C are planned.

### 7.4 Alternative Methods

| Objective | Standard Method | Alternative | Justification |
|-----------|-----------------|-------------|---------------|
| A-5.5 (Accuracy) | Low-level test | SPARK proof | DO-333 credit |

---

## 8. Certification Basis

### 8.1 Applicable Standards

| Standard | Version | Application |
|----------|---------|-------------|
| DO-178C | 2011 | Primary |
| DO-330 | 2011 | Tool qualification |
| DO-333 | 2011 | Formal methods |

### 8.2 Certification Authority

To be determined based on integration context:
- FAA (US civil aviation)
- EASA (European aviation)
- NASA (space systems)
- ESA (European space)

### 8.3 Previously Developed Software

The library is new development. No previously developed or COTS software is used within the library scope. The Ada runtime and compiler are qualified tools.

---

## 9. Compliance Summary

### 9.1 Table A-1: Planning Process Objectives

| ID | Objective | Compliance |
|----|-----------|------------|
| 1 | SW planning defines activities | SDP, SVP, SCMP, SQAP |
| 2 | Transition criteria defined | SDP Section 10 |
| 3 | SW dev environment selected | SDP Section 5 |
| 4 | Standards defined | SDP Section 4 |
| 5 | Dev environment documented | SDP Section 5 |
| 6 | Plans are approved | CCB approval |

### 9.2 Table A-2: Development Process Objectives

| ID | Objective | Compliance |
|----|-----------|------------|
| 1 | HLR developed | Pre/Post contracts |
| 2 | Derived requirements addressed | Type constraints |
| 3 | SW architecture developed | `docs/architecture/` |
| 4 | LLR developed | Function contracts |
| 5 | Source code developed | 14 packages |
| 6 | Executable code produced | CI builds |
| 7 | Traceability established | RTM |

### 9.3 Table A-3 through A-7

See SVP for detailed compliance mapping.

---

## 10. Certification Schedule

### 10.1 Milestones

| Milestone | Target | Deliverable |
|-----------|--------|-------------|
| Phase 1 Complete | Week 6 | Plans approved |
| Phase 2 Complete | Week 10 | Contracts strengthened |
| Phase 3 Complete | Week 16 | Tests complete |
| Phase 4 Complete | Week 19 | Ready for certification |
| Certification Audit | TBD | Package reviewed |
| Certification Granted | TBD | Approval issued |

### 10.2 Certification Package

Final package includes:
- All plans (PSAC, SDP, SVP, SCMP, SQAP)
- Requirements (RTM)
- Design documentation
- Source code
- Test procedures and results
- Coverage analysis
- SPARK analysis
- Compliance matrix

---

## 11. Certification Maintenance

### 11.1 Change Impact Analysis

For post-certification changes:
1. Classify change (major/minor)
2. Analyze impact on certification
3. Update affected artifacts
4. Re-verify as required
5. Submit to certification authority

### 11.2 Configuration Control

All changes controlled per SCMP.

---

## 12. References

### 12.1 Standards

- RTCA DO-178C (2011)
- RTCA DO-330 (2011)
- RTCA DO-333 (2011)

### 12.2 Project Documents

- HALE-SDP-001: Software Development Plan
- HALE-SVP-001: Software Verification Plan
- HALE-SCMP-001: Software Configuration Management Plan
- HALE-SQAP-001: Software Quality Assurance Plan

### 12.3 Technical References

- Hale, F.J. (1994). Introduction to Space Flight. Prentice Hall.
- Vallado, D.A. (2013). Fundamentals of Astrodynamics and Applications.

---

## Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-01-06 | | Initial release |

---

## Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Project Manager | | | |
| QA Manager | | | |
| Certification Authority | | | |
