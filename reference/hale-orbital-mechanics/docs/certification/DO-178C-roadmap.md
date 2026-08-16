# DO-178C Certification Roadmap

## HALE Orbital Mechanics Library - Certification Strategy

This document outlines the certification pathway for using the HALE Orbital Mechanics Library in safety-critical avionics and space systems under DO-178C (Software Considerations in Airborne Systems and Equipment Certification).

---

## 1. Overview

### 1.1 Purpose

The HALE Orbital Mechanics Library is designed with certification in mind. While the library itself is not certified, its architecture supports integration into certified systems at various Design Assurance Levels (DAL).

### 1.2 Applicable Standards

| Standard | Domain | Relevance |
|----------|--------|-----------|
| DO-178C | Avionics Software | Primary certification standard |
| DO-278A | Ground-Based CNS/ATM | Ground systems |
| DO-330 | Tool Qualification | Development tools |
| DO-331 | Model-Based Development | Formal methods supplement |
| DO-332 | Object-Oriented Technology | Ada-specific guidance |
| DO-333 | Formal Methods | SPARK verification credit |
| ECSS-E-ST-40C | Space Engineering | ESA software standard |
| NASA-STD-8719.13 | Software Safety | NASA requirements |

### 1.3 Design Assurance Levels

| Level | Failure Condition | Objectives |
|-------|-------------------|------------|
| A | Catastrophic | 71 objectives, MC/DC coverage |
| B | Hazardous | 69 objectives, decision coverage |
| C | Major | 62 objectives, statement coverage |
| D | Minor | 26 objectives, minimal |
| E | No Effect | No objectives |

---

## 2. Current Library Status

### 2.1 Certification-Ready Features

| Feature | Status | DO-178C Benefit |
|---------|--------|-----------------|
| SPARK_Mode specifications | Implemented | Formal verification credit (DO-333) |
| Pre/Post contracts | Implemented | Requirements traceability |
| Dimensional types | Implemented | Eliminates unit confusion errors |
| Ghost functions | Implemented | Mathematical property verification |
| Deterministic FP mode | Implemented | Cross-platform reproducibility |
| Test framework | Implemented | Verification evidence |

### 2.2 SPARK Verification Coverage

```
Package Coverage Status:
+----------------------+-------+-------+
| Package              | Spec  | Body  |
+----------------------+-------+-------+
| Hale_Orbital.Types   | SPARK | N/A   | <- Pure types, fully verified
| Hale_Orbital.Constants| SPARK| N/A   | <- Pure constants
| Hale_Orbital.Vectors | SPARK | Off   | <- Contracts verified
| Hale_Orbital.Matrices| SPARK | Off   | <- Contracts verified
| Hale_Orbital.Twobody | SPARK | Off   | <- Contracts verified
| Hale_Orbital.Elements| SPARK | Off   | <- Contracts verified
| Hale_Orbital.Kepler  | SPARK | Off   | <- Loop invariants added
| Hale_Orbital.Lambert | SPARK | Off   | <- Contracts verified
| Hale_Orbital.Maneuvers| SPARK| Off   | <- Contracts verified
+----------------------+-------+-------+
```

### 2.3 Gap Analysis

| Requirement | Current State | Gap |
|-------------|---------------|-----|
| MC/DC Coverage | ~60% estimated | Need 100% for Level A |
| Requirements Traceability | Partial | Need formal matrix |
| Configuration Management | Git-based | Need formal CM plan |
| Problem Reports | GitHub Issues | Need formal PR system |
| Tool Qualification | Not started | Need DO-330 evidence |

---

## 3. Certification Pathway

### 3.1 Phase 1: Foundation (Current)

**Objective**: Establish certification-compatible architecture

**Completed Work**:
- [x] SPARK_Mode on all specification files
- [x] Pre/Post contracts on all public functions
- [x] Dimensional types preventing unit errors
- [x] Ghost functions for mathematical properties
- [x] Deterministic floating-point build mode
- [x] AUnit-compatible test framework

**Evidence Artifacts**:
- Source code with SPARK annotations
- Contract specifications
- Test procedures and results
- Design rationale documents (DEC-001 through DEC-004)

### 3.2 Phase 2: Formal Methods Credit (DO-333)

**Objective**: Achieve formal methods credit per DO-333 supplement

**Required Work**:
- [ ] Complete SPARK proof runs with GNATprove
- [ ] Document proof coverage report
- [ ] Resolve or justify all unproven VCs
- [ ] Create formal methods plan per DO-333 Section 4

**Credit Available**:
| Activity | Traditional | With DO-333 |
|----------|-------------|-------------|
| Code Reviews | Required | Reduced |
| Low-Level Testing | 100% coverage | Proof substitutes |
| Structural Coverage | MC/DC | Proof substitutes |

**SPARK Proof Strategy**:
```
Level 1: Flow analysis (absence of errors)
  - No uninitialized reads
  - No ineffective statements
  - Correct Global/Depends contracts

Level 2: Absence of run-time errors
  - No division by zero
  - No overflow
  - No range violations

Level 3: Functional correctness
  - Postconditions proven
  - Loop invariants verified
  - Mathematical properties hold
```

### 3.3 Phase 3: Testing Evidence

**Objective**: Demonstrate test coverage per DAL requirements

**Test Categories**:

| Category | Purpose | Status |
|----------|---------|--------|
| Unit Tests | Individual function verification | Partial |
| Integration Tests | Inter-package behavior | Needed |
| Edge Case Tests | Boundary conditions | Implemented |
| Vallado Validation | Textbook reference values | Implemented |
| Performance Tests | Timing requirements | Implemented |

**Coverage Targets**:
- Level A: 100% MC/DC (Modified Condition/Decision Coverage)
- Level B: 100% Decision Coverage
- Level C: 100% Statement Coverage

**Recommended Tools**:
- GNATcoverage for structural coverage analysis
- GNATtest for test harness generation
- GNATprove for SPARK proof coverage

### 3.4 Phase 4: Documentation Package

**Objective**: Complete certification documentation

**Required Documents**:

| Document | DO-178C Section | Status |
|----------|-----------------|--------|
| Plan for Software Aspects of Certification (PSAC) | 11.1 | Template needed |
| Software Development Plan (SDP) | 11.2 | Template needed |
| Software Verification Plan (SVP) | 11.3 | Template needed |
| Software Configuration Management Plan (SCMP) | 11.4 | Git-based, needs formalization |
| Software Quality Assurance Plan (SQAP) | 11.5 | Template needed |
| Software Requirements Standards (SRS) | 11.6 | Contracts serve as basis |
| Software Design Standards (SDS) | 11.7 | Rationale docs serve as basis |
| Software Code Standards (SCS) | 11.8 | Ada style guide |

**Data Items**:
| Data Item | Purpose | Status |
|-----------|---------|--------|
| Software Requirements Data | What the software must do | Contracts |
| Software Design Description | How it's structured | Architecture docs |
| Source Code | Implementation | Complete |
| Executable Object Code | Built binary | CI/CD generated |
| Software Verification Results | Test outcomes | Partial |
| Software Life Cycle Environment Configuration Index | Tools used | Needed |

---

## 4. Integration Guidance

### 4.1 Using HALE in Certified Systems

**Scenario A: Level D/E Application**
- Use library directly
- Run standard test suite
- Document integration testing

**Scenario B: Level C Application**
- Enable runtime assertions (`-gnata`)
- Achieve statement coverage on integrated code
- Review Pre/Post contracts for requirements traceability

**Scenario C: Level A/B Application**
- Run SPARK proofs with GNATprove
- Supplement with MC/DC testing where proofs unavailable
- Generate formal methods certification package per DO-333
- Consider library as COTS and apply appropriate credit

### 4.2 COTS Considerations

Per DO-178C Section 12.3, using this library as Commercial Off-The-Shelf software requires:

1. **Service History**: Document successful usage in similar applications
2. **Product Assessment**: Verify library meets system requirements
3. **Development Process**: This documentation + SPARK proofs
4. **Verification Process**: Test suite + integration testing

### 4.3 Compiler Configuration

For certification, use deterministic build mode:

```bash
gprbuild -P hale_orbital.gpr -XBUILD_MODE=deterministic
```

This enables:
- `-ffp-contract=off`: No FMA contractions (reproducible math)
- `-fno-fast-math`: Strict IEEE 754 compliance
- `-frounding-math`: Honor rounding mode
- `-fsignaling-nans`: Detect NaN operations

---

## 5. Evidence Matrix

### 5.1 Requirements Traceability

| Requirement Source | Implementation | Verification |
|-------------------|----------------|--------------|
| Hale Textbook | Algorithm code | Vallado tests |
| Contract preconditions | Input validation | Unit tests |
| Contract postconditions | Output guarantees | SPARK proofs |
| Mathematical properties | Ghost functions | GNATprove |

### 5.2 Structural Coverage Mapping

| Package | Statement | Decision | MC/DC | Proof |
|---------|-----------|----------|-------|-------|
| Types | N/A | N/A | N/A | Full |
| Constants | N/A | N/A | N/A | Full |
| Vectors | Partial | Partial | TBD | Contracts |
| Twobody | Partial | Partial | TBD | Contracts |
| Kepler | Partial | Partial | TBD | Invariants |
| Lambert | Partial | Partial | TBD | Contracts |
| Maneuvers | Partial | Partial | TBD | Contracts |
| Propagation | Partial | Partial | TBD | Limited |

---

## 6. Tool Qualification (DO-330)

### 6.1 Development Tools

| Tool | Category | Qualification Need |
|------|----------|-------------------|
| GNAT Pro | Compiler | TQL-1 for Level A |
| GNATprove | Verification | TQL-1/2 |
| GNATcoverage | Coverage Analysis | TQL-1 |
| GNATtest | Test Generation | TQL-2 |
| gprbuild | Build System | TQL-3 |

### 6.2 Tool Qualification Strategy

For Level A certification:
- Use AdaCore's pre-qualified tool suite
- Document tool usage in SLECI
- Apply tool qualification evidence from AdaCore

---

## 7. Certification Timeline

### 7.1 Milestones

| Phase | Activity | Dependencies |
|-------|----------|--------------|
| Foundation | Architecture setup | None (Complete) |
| Proofs | GNATprove runs | GNATprove license |
| Testing | MC/DC coverage | GNATcoverage license |
| Documentation | Certification package | Proofs + Tests |
| Audit | DER review | Documentation |

### 7.2 Effort Estimates

| Activity | Person-Months | Notes |
|----------|---------------|-------|
| SPARK Proofs | 2-4 | Depends on VC complexity |
| Test Development | 2-3 | For full coverage |
| Documentation | 2-3 | Templates accelerate |
| Integration | 1-2 | Per project |

---

## 8. Risk Management

### 8.1 Technical Risks

| Risk | Mitigation |
|------|------------|
| Unproven VCs | Supplement with testing |
| Generic instantiation | Bodies have SPARK_Mode Off |
| Floating-point proofs | Use deterministic mode |
| Tool availability | Use AdaCore toolchain |

### 8.2 Process Risks

| Risk | Mitigation |
|------|------------|
| Requirements volatility | Contract-driven development |
| Integration complexity | Modular architecture |
| Schedule pressure | Phased certification |

---

## 9. References

### 9.1 Standards Documents

- RTCA DO-178C: Software Considerations in Airborne Systems
- RTCA DO-330: Software Tool Qualification Considerations
- RTCA DO-331: Model-Based Development and Verification
- RTCA DO-332: Object-Oriented Technology and Related Techniques
- RTCA DO-333: Formal Methods Supplement

### 9.2 SPARK/GNAT Resources

- AdaCore SPARK User's Guide
- GNAT Pro User's Guide
- GNATcoverage User's Manual
- GNATprove User's Guide

### 9.3 Library Documentation

- DEC-001: Dimensional Types Rationale
- DEC-002: SPARK Strategy
- DEC-003: Contract Design
- DEC-004: Floating-Point Determinism

---

## 10. Contact and Support

For certification assistance:
- Review AdaCore's certification support services
- Consult with a Designated Engineering Representative (DER)
- Engage certification authority early in project planning

---

*Document Version: 1.0*
*Last Updated: 2026-01-05*
*Classification: Public*
