# Software Development Plan (SDP)

## HALE Orbital Mechanics Library

**Document Number:** HALE-SDP-001
**Version:** 1.0
**Date:** 2026-01-06
**Classification:** Internal Use
**DO-178C Reference:** Section 11.2

---

## 1. Purpose and Scope

### 1.1 Purpose

This Software Development Plan (SDP) defines the development processes, methods, standards, and environment used to develop the HALE Orbital Mechanics Library. It establishes the framework for producing software that meets DO-178C objectives for DAL C.

### 1.2 Scope

This plan covers:
- Software development lifecycle
- Development methods and standards
- Development environment
- Transition criteria between phases
- Integration with other lifecycle processes

### 1.3 Software Overview

| Attribute | Value |
|-----------|-------|
| **Name** | HALE Orbital Mechanics Library |
| **Language** | Ada 2012 with SPARK 2014 |
| **Target DAL** | C (Major Failure Condition) |
| **Domain** | Orbital mechanics computations |
| **Platform** | Cross-platform (Linux, Windows, macOS) |

---

## 2. Referenced Documents

| Document | Description |
|----------|-------------|
| HALE-SCMP-001 | Software Configuration Management Plan |
| HALE-SQAP-001 | Software Quality Assurance Plan |
| HALE-SVP-001 | Software Verification Plan |
| HALE-PSAC-001 | Plan for Software Aspects of Certification |
| DO-178C | Software Considerations in Airborne Systems |
| DO-333 | Formal Methods Supplement |

---

## 3. Software Life Cycle

### 3.1 Life Cycle Model

The project uses an **Iterative Development** model with formal phase gates:

```
┌─────────────┐
│  Planning   │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────────────────────────────┐
│ Requirements│     │                                     │
└──────┬──────┘     │         Iteration Loop              │
       │            │                                     │
       ▼            │  ┌────────┐  ┌────────┐  ┌────────┐ │
┌─────────────┐     │  │ Design │─▶│  Code  │─▶│  Test  │ │
│   Design    │─────┼─▶│        │  │        │  │        │ │
└──────┬──────┘     │  └────────┘  └────────┘  └───┬────┘ │
       │            │       ▲                      │      │
       ▼            │       └──────────────────────┘      │
┌─────────────┐     │                                     │
│Implementation│────┴─────────────────────────────────────┘
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Verification│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Certification│
└─────────────┘
```

### 3.2 Phase Definitions

#### Planning Phase
- Establish project plans (SDP, SVP, SCMP, SQAP, PSAC)
- Define development environment
- Establish baselines
- **Exit:** Plans approved by CCB

#### Requirements Phase
- Define high-level requirements (HLR)
- Establish traceability to source
- Review and approve HLRs
- **Exit:** RTM complete, HLR review passed

#### Design Phase
- Define software architecture
- Define low-level requirements (contracts)
- Design rationale documentation
- **Exit:** Design review passed

#### Implementation Phase
- Code development
- Unit testing
- SPARK annotation
- Code review
- **Exit:** Code review passed, unit tests pass

#### Verification Phase
- Integration testing
- Coverage analysis
- SPARK proof
- Verification reporting
- **Exit:** All tests pass, coverage met

#### Certification Phase
- Compile certification package
- Certification liaison
- Audit support
- **Exit:** Certification granted

---

## 4. Development Standards

### 4.1 Coding Standards

#### Ada/SPARK Standards

| Standard | Enforcement | Reference |
|----------|-------------|-----------|
| Ada 2012 | Compiler | ARM |
| SPARK 2014 | GNATprove | SPARK RM |
| GNAT Style | `-gnatyg` | GNAT UG |
| GNAT Warnings | `-gnatwa` | GNAT UG |

#### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Package | Mixed_Case | `Hale_Orbital.Kepler` |
| Type | Mixed_Case | `Orbital_Elements` |
| Constant | Mixed_Case | `Mu_Earth` |
| Variable | Lower_Case | `semi_major_axis` |
| Function | Mixed_Case | `Solve_Kepler` |
| Procedure | Mixed_Case | `Propagate_State` |
| Parameter | Mixed_Case | `Initial_State` |

#### File Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Spec | `package-child.ads` | `hale_orbital-kepler.ads` |
| Body | `package-child.adb` | `hale_orbital-kepler.adb` |
| Test | `package_test.adb` | `hale_tests-kepler.adb` |

### 4.2 Design Standards

#### Architecture Principles

1. **Modularity**: One package per domain concept
2. **Layering**: Types → Operations → Solvers → Applications
3. **Encapsulation**: Private types where appropriate
4. **Pure Functions**: Prefer functions over procedures
5. **SPARK First**: Specs always SPARK_Mode => On

#### Package Structure

```ada
package Hale_Orbital.Feature
   with SPARK_Mode => On
is
   -- Type definitions
   type Feature_Type is ...;

   -- Constants
   Feature_Constant : constant := ...;

   -- Functions with contracts
   function Compute_Feature (...) return Result
      with Pre  => ...,
           Post => ...,
           Global => null;

   -- Procedures with contracts (rare)
   procedure Update_Feature (...)
      with Pre     => ...,
           Post    => ...,
           Global  => null,
           Depends => ...;

private
   -- Implementation details
end Hale_Orbital.Feature;
```

### 4.3 Documentation Standards

#### Code Comments

```ada
-------------------------------------------------------------------------------
-- Package_Name - Brief Description
-------------------------------------------------------------------------------
-- Extended description of package purpose.
-- Mathematical background if relevant.
--
-- Reference: Textbook/Paper citation
-------------------------------------------------------------------------------

-- Function brief description
-- Detailed explanation of algorithm
-- Reference: Equation number from textbook
function Compute (...) return Result;
```

#### Contract Documentation

```ada
function Solve (X : Input) return Output
   with Pre  => X > 0.0,  -- Input must be positive
        Post => Solve'Result in 0.0 .. 1.0;  -- Output normalized
```

---

## 5. Development Environment

### 5.1 Hardware Environment

| Component | Specification |
|-----------|---------------|
| Development | x86_64, 16GB+ RAM |
| CI/CD | GitHub Actions runners |
| Target | Platform-independent |

### 5.2 Software Environment

#### Development Tools

| Tool | Version | Purpose |
|------|---------|---------|
| GNAT Pro | 24.x | Ada compiler |
| GNATprove | 24.x | SPARK prover |
| GNATcoverage | 24.x | Coverage analysis |
| gprbuild | 24.x | Build system |
| Git | 2.x | Version control |
| VS Code | Latest | IDE (optional) |

#### Build Modes

| Mode | Flags | Purpose |
|------|-------|---------|
| `debug` | `-g -O0 -gnata` | Development |
| `release` | `-O2 -gnatn` | Performance |
| `spark` | `-gnata -gnatVa` | SPARK analysis |
| `deterministic` | `-ffp-contract=off` | Certification |

#### Build Command

```bash
# Standard build
gprbuild -P ada/hale_orbital.gpr -XBUILD_MODE=release

# SPARK analysis
gnatprove -P ada/hale_orbital.gpr --level=2

# Coverage build
gprbuild -P ada/hale_orbital.gpr -XBUILD_MODE=debug --coverage
gnatcov run --project=ada/hale_orbital.gpr ./tests/hale_tests
gnatcov coverage --annotate=html
```

### 5.3 CI/CD Pipeline

```yaml
# .github/workflows/ada.yml
jobs:
  build:
    - Checkout code
    - Setup GNAT
    - Build (debug, release, deterministic)
    - Run tests
    - SPARK flow analysis
    - Coverage report
    - Archive artifacts
```

---

## 6. Requirements Development

### 6.1 Requirements Sources

| Source | Type | Example |
|--------|------|---------|
| Hale Textbook | Algorithm requirements | "Solve Kepler's equation" |
| Vallado Reference | Validation data | Reference orbital values |
| Safety Analysis | Safety requirements | "No division by zero" |
| User Needs | Interface requirements | "Cross-platform" |

### 6.2 Requirements Structure

```
HLR-<package>-<number>: <description>
  Pre: <preconditions>
  Post: <postconditions>
  Source: <reference>
  Test: <test procedure>
```

### 6.3 Requirements Attributes

| Attribute | Description |
|-----------|-------------|
| ID | Unique identifier |
| Description | Requirement text |
| Source | Origin (textbook, safety, user) |
| Type | Functional / Non-functional |
| Priority | Critical / High / Medium / Low |
| Status | Draft / Reviewed / Approved |
| Trace-Up | Parent requirement |
| Trace-Down | Implementation / Test |

---

## 7. Design Process

### 7.1 Architecture Design

1. Identify domain concepts (packages)
2. Define package interfaces (specifications)
3. Define data types
4. Define operations with contracts
5. Document design rationale (DEC-*)

### 7.2 Detailed Design

1. Define algorithms
2. Define contracts (Pre/Post)
3. Define SPARK annotations (Global/Depends)
4. Define ghost functions for proofs
5. Trace to requirements

### 7.3 Design Reviews

| Review | Scope | Participants |
|--------|-------|--------------|
| Architecture | Package structure, interfaces | Tech Lead, QA |
| Detailed Design | Contracts, algorithms | Developer, Reviewer |
| SPARK | Annotations, proofs | SPARK expert |

---

## 8. Coding Process

### 8.1 Implementation Sequence

1. Create package specification
2. Add SPARK_Mode, contracts, Global
3. Implement package body
4. Add SPARK body annotations (or Off)
5. Create unit tests
6. Run SPARK flow analysis
7. Run unit tests
8. Code review

### 8.2 SPARK Strategy

| Element | SPARK Mode | Rationale |
|---------|------------|-----------|
| Specifications | ON | Enable formal verification |
| Pure Bodies | ON | Full proof capability |
| Generic Bodies | Off | Generics not SPARK compatible |
| Numeric Bodies | Off | Elementary functions not SPARK |

### 8.3 Code Review Requirements

All code changes require review covering:

- [ ] Functional correctness
- [ ] Contract completeness
- [ ] SPARK compliance
- [ ] Coding standards
- [ ] Traceability
- [ ] Test coverage

---

## 9. Integration Process

### 9.1 Integration Order

```
1. Types, Constants (foundation)
2. Vectors, Matrices (utilities)
3. Stumpff (mathematical functions)
4. Twobody (basic dynamics)
5. Elements (coordinate systems)
6. Kepler (propagation)
7. Lambert (targeting)
8. Maneuvers (mission design)
9. Propagation (numerical integration)
10. Threebody (advanced dynamics)
11. Interplanetary (applications)
```

### 9.2 Integration Testing

At each integration step:
1. Build complete library
2. Run all unit tests
3. Run integration tests
4. Verify no regressions

---

## 10. Transition Criteria

### 10.1 Requirements → Design

- [ ] All HLRs documented and approved
- [ ] RTM complete with traceability
- [ ] Requirements review complete
- [ ] QA audit passed

### 10.2 Design → Implementation

- [ ] Architecture documented
- [ ] Package interfaces defined
- [ ] Design review complete
- [ ] SPARK annotations designed

### 10.3 Implementation → Verification

- [ ] All code implemented
- [ ] All code reviewed
- [ ] Unit tests pass
- [ ] SPARK flow analysis clean
- [ ] RTM updated with implementation

### 10.4 Verification → Certification

- [ ] All tests pass
- [ ] Coverage targets met
- [ ] SPARK proofs complete (or documented)
- [ ] Verification report complete
- [ ] All problem reports closed

---

## 11. Data Management

### 11.1 Work Products

| Product | Format | Location |
|---------|--------|----------|
| Source Code | Ada | `ada/src/` |
| Test Code | Ada | `ada/tests/` |
| Requirements | Markdown | `docs/certification/rtm.md` |
| Design | Markdown | `docs/architecture/` |
| Rationale | Markdown | `docs/rationale/` |

### 11.2 Development Data

| Data | Purpose | Retention |
|------|---------|-----------|
| Build logs | Debugging | 1 year |
| Test results | Verification | Product life |
| SPARK output | Proof evidence | Product life |
| Coverage data | Verification | Product life |

---

## 12. Resource Requirements

### 12.1 Personnel

| Role | Responsibilities |
|------|------------------|
| Technical Lead | Architecture, integration |
| Developer | Implementation, unit testing |
| SPARK Engineer | Formal verification |
| Test Engineer | Integration testing |
| QA Engineer | Reviews, audits |
| Documentation | Technical writing |

### 12.2 Tools

| Tool | License | Source |
|------|---------|--------|
| GNAT Pro | Commercial | AdaCore |
| GNATprove | Commercial | AdaCore |
| GNATcoverage | Commercial | AdaCore |
| Git | Open source | - |
| GitHub | Subscription | GitHub |

---

## 13. Schedule

### 13.1 Phase Duration

| Phase | Duration | Milestone |
|-------|----------|-----------|
| Phase 1: Foundation | 6 weeks | Plans complete |
| Phase 2: Contracts | 4 weeks | Contracts complete |
| Phase 3: Testing | 6 weeks | Tests complete |
| Phase 4: Verification | 3 weeks | Ready for certification |

### 13.2 Major Milestones

| Milestone | Target | Criteria |
|-----------|--------|----------|
| M1: Plans Approved | Week 6 | All plans reviewed |
| M2: Contracts Complete | Week 10 | All ISS-001 to ISS-038 closed |
| M3: Tests Complete | Week 16 | 100% coverage |
| M4: Certification Ready | Week 19 | All evidence packaged |

---

## 14. Risk Management

### 14.1 Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| SPARK VC unprovable | Medium | High | Document exemption, add tests |
| Coverage gaps | Low | Medium | Systematic test design |
| Tool issues | Low | Medium | Vendor support |

### 14.2 Schedule Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Resource constraints | Medium | Medium | Phased approach |
| Requirements changes | Low | High | Change control |
| Integration issues | Low | Medium | Incremental integration |

---

## Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-01-06 | | Initial release |

---

## Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Technical Lead | | | |
| QA Manager | | | |
| Project Manager | | | |
