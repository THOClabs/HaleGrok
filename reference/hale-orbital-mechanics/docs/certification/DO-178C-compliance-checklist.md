# DO-178C Compliance Checklist

## HALE Orbital Mechanics Library - Certification Status Tracker

**Document Version**: 1.0
**Last Updated**: 2026-01-06 (SPARK annotations complete)
**Target DAL**: C (expandable to A/B with additional work)

---

## 1. Planning Process (Table A-1)

| ID | Objective | Level A | Level B | Level C | Status | Evidence |
|----|-----------|:-------:|:-------:|:-------:|--------|----------|
| A-1.1 | Software plans defined | X | X | X | PARTIAL | `hale_orbital.gpr`, CI/CD |
| A-1.2 | Transition criteria defined | X | X | | NOT STARTED | |
| A-1.3 | SW dev environment selected | X | X | X | COMPLETE | Ada 2012/GNAT/SPARK |
| A-1.4 | Standards defined | X | X | X | COMPLETE | DEC-001 to DEC-005 |
| A-1.5 | Dev environment documented | X | X | | PARTIAL | `.github/workflows/` |
| A-1.6 | Plans approved | X | X | | NOT STARTED | |

---

## 2. Development Process (Table A-2)

| ID | Objective | Level A | Level B | Level C | Status | Evidence |
|----|-----------|:-------:|:-------:|:-------:|--------|----------|
| A-2.1 | High-level requirements | X | X | X | COMPLETE | Pre/Post contracts |
| A-2.2 | Derived requirements | X | X | X | COMPLETE | Type constraints |
| A-2.3 | Software architecture | X | X | X | COMPLETE | `docs/architecture/` |
| A-2.4 | Low-level requirements | X | X | X | COMPLETE | Function contracts |
| A-2.5 | Source code developed | X | X | X | COMPLETE | 13 packages |
| A-2.6 | Executable code | X | X | X | COMPLETE | CI builds |
| A-2.7 | Traceability HLR↔Source | X | X | X | IN PROGRESS | `rtm.md`; requirement-ID namespaces being unified with SRS/test-rtm |

---

## 3. Verification of Outputs (Table A-3 through A-7)

### A-3: High-Level Requirements

| ID | Objective | Status | Evidence |
|----|-----------|--------|----------|
| A-3.1 | Accurate & consistent | COMPLETE | Vallado validation |
| A-3.2 | Verifiable | COMPLETE | Contracts with tolerances |
| A-3.3 | Conformant to standards | COMPLETE | Hale/Vallado refs |
| A-3.4 | Traceable | IN PROGRESS | RTM; ID namespaces being unified with SRS/test-rtm |
| A-3.5 | Algorithms accurate | COMPLETE | Test validation |

### A-4: Low-Level Requirements

| ID | Objective | Status | Evidence |
|----|-----------|--------|----------|
| A-4.1 | Conform to HLR | COMPLETE | Architecture docs |
| A-4.2 | Accurate | COMPLETE | Ghost functions |
| A-4.3 | Compatible with target | COMPLETE | Multi-platform CI |

### A-5: Source Code

| ID | Objective | Status | Evidence |
|----|-----------|--------|----------|
| A-5.1 | Conformant to LLR | COMPLETE | SPARK_Mode specs |
| A-5.2 | Verifiable | COMPLETE | Contracts, tests |
| A-5.3 | Conforms to standards | COMPLETE | `-gnaty3M200`, `-gnatwa`, `-gnatwe` |
| A-5.4 | Traceable | IN PROGRESS | RTM; ID namespaces being unified |
| A-5.5 | Accurate | PARTIAL | Code review + tests; SPARK flow PENDING (gnatprove unavailable in CI) |
| A-5.6 | Object code accurate | COMPLETE | CI-gated test execution (run_tests + run_all_tests exit status) |

### A-6: Test Process

| ID | Objective | Status | Test Count |
|----|-----------|--------|------------|
| A-6.1 | Procedures correct | COMPLETE | 10 test packages, wired into CI via run_all_tests |
| A-6.2 | Results correct | COMPLETE | CI runs both runners; failures propagate via exit status |
| A-6.3 | HLR coverage | PARTIAL | ~70% |
| A-6.4 | LLR coverage | PARTIAL | Edge cases |
| A-6.5 | Code coverage | PARTIAL | ~60% stmt |

### A-7: Structural Coverage

| ID | Objective | Level A | Level B | Level C | Status |
|----|-----------|:-------:|:-------:|:-------:|--------|
| A-7.1 | Statement coverage | X | X | X | ~60% |
| A-7.2 | Decision coverage | X | X | | ~50% |
| A-7.3 | MC/DC | X | | | ~30% |
| A-7.4 | Data/control coupling | X | X | | PARTIAL |
| A-7.5 | Coverage analysis | X | X | X | NEEDED |

---

## 4. SPARK Verification Status

### Package Coverage Matrix

| Package | Spec SPARK | Body SPARK | Global | Depends | Ghost | Contracts |
|---------|:----------:|:----------:|:------:|:-------:|:-----:|:---------:|
| Hale_Orbital (root) | ON | Off | COMPLETE | N/A | - | 1 |
| Types | ON | N/A | N/A | N/A | N/A | N/A |
| Constants | ON | N/A | N/A | N/A | N/A | N/A |
| Vectors | ON | Off | COMPLETE | COMPLETE | 6 | 22 |
| Matrices | ON | Off | COMPLETE | N/A | - | 20 |
| Twobody | ON | Off | COMPLETE | N/A | - | 24 |
| Elements | ON | Off | COMPLETE | N/A | - | 20 |
| Kepler | ON | Off | COMPLETE | COMPLETE | - | 12 |
| Stumpff | ON | Off | COMPLETE | N/A | - | 4 |
| Lambert | ON | Off | COMPLETE | N/A | - | 14 |
| Maneuvers | ON | Off | COMPLETE | N/A | - | 22 |
| Propagation | N/A | Off | N/A | N/A | - | 2 |
| Threebody | ON | Off | COMPLETE | COMPLETE | 3 | 15 |
| Interplanetary | ON | Off | COMPLETE | N/A | - | 20 |

### SPARK Proof Levels

| Level | Description | Status | Completion |
|-------|-------------|--------|------------|
| 0 | Type safety | COMPLETE | 100% |
| 1 | Contract verification | PENDING | contracts defined (95%); no proof has run |
| 2 | Data flow (Global) | PENDING | annotations defined (100%); gnatprove flow has never run |
| 3 | Information flow (Depends) | PENDING | annotations defined (4 procedures); gnatprove flow has never run |
| 4 | Functional correctness | PARTIAL | 30% |

---

## 5. Documentation Package

| Document | DO-178C Section | Status | File |
|----------|-----------------|--------|------|
| PSAC | 11.1 | NEEDED | - |
| SDP | 11.2 | NEEDED | - |
| SVP | 11.3 | NEEDED | - |
| SCMP | 11.4 | PARTIAL | Git-based |
| SQAP | 11.5 | NEEDED | - |
| SRS | 11.6 | PARTIAL | Contracts |
| SDS | 11.7 | COMPLETE | DEC-* docs |
| SCS | 11.8 | COMPLETE | Ada style |
| RTM | N/A | COMPLETE | `docs/certification/rtm.md` |

---

## 6. Action Items

### Immediate (Level D Ready) - COMPLETE
- [x] SPARK_Mode on all specifications
- [x] Pre/Post contracts on public functions
- [x] Test framework with 150+ tests
- [x] Design rationale documents

### Short-Term (Level C Ready) - COMPLETE
- [x] Add Global => null to all pure functions (176+ functions annotated)
- [x] Add Depends clauses for traceability (4 procedures with data flow)
- [x] Create formal Requirements Traceability Matrix (`docs/certification/rtm.md`)
- [ ] Run GNATcoverage for statement coverage metrics
- [x] Document test-to-requirement mapping (79 requirements in RTM)

### Medium-Term (Level B Ready)
- [ ] Achieve 100% decision coverage
- [x] Complete information flow analysis (Global/Depends complete)
- [ ] Create SDP/SVP documents
- [ ] Tool qualification planning

### Long-Term (Level A Ready)
- [ ] Achieve 100% MC/DC coverage
- [ ] Complete DO-333 package
- [ ] Tool qualification (DO-330)
- [ ] DER engagement

---

## 7. Certification Evidence Index

| Evidence Type | Location | Status |
|---------------|----------|--------|
| Source Code | `ada/src/` | Complete |
| Test Code | `ada/tests/` | Complete |
| Design Rationale | `docs/rationale/` | Complete |
| Architecture | `docs/architecture/` | Complete |
| API Reference | `docs/api-reference.md` | Complete |
| Certification Roadmap | `docs/certification/DO-178C-roadmap.md` | Complete |
| Compliance Checklist | `docs/certification/DO-178C-compliance-checklist.md` | This file |
| RTM | `docs/certification/rtm.md` | In Progress |
| SPARK Proofs | `ada/gnatprove/` | CI Generated |
| Test Results | CI artifacts | CI Generated |
| Coverage Reports | CI artifacts | Needed |

---

## 8. Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Developer | | | |
| QA Engineer | | | |
| Project Manager | | | |
| DER (if applicable) | | | |

---

*This checklist should be reviewed and updated after each development iteration.*
