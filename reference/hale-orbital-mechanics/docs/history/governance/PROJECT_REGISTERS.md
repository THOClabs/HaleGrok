# HALE Orbital Mechanics - Project Registers

## Last Updated: January 2026

---

## 1. Decision Register

### DEC-001: Primary Language Selection
| Field | Value |
|-------|-------|
| **Decision** | Ada 2012 as primary implementation language |
| **Date** | January 2026 |
| **Made By** | Expert Panel (Unanimous) |
| **Rationale** | Type safety prevents dimensional errors (Mars Climate Orbiter), contracts document behavior, SPARK enables formal verification for safety-critical applications |
| **Alternatives Considered** | Python (current), C++ (performance), Rust (memory safety) |
| **Status** | Approved |

### DEC-002: SPARK Mode Strategy
| Field | Value |
|-------|-------|
| **Decision** | Enable SPARK_Mode on pure computational packages |
| **Date** | January 2026 |
| **Made By** | Brosgol, Taft |
| **Rationale** | Core numerical routines benefit from formal verification; I/O and external interfaces remain standard Ada |
| **SPARK Packages** | Types, Constants, Vectors, Matrices, TwoBody, Kepler |
| **Non-SPARK Packages** | File I/O, Visualization, External interfaces |
| **Status** | Approved |

### DEC-003: Dimensional Type System
| Field | Value |
|-------|-------|
| **Decision** | Use derived types (not subtypes) for dimensions |
| **Date** | January 2026 |
| **Made By** | Ichbiah, Barnes |
| **Rationale** | Derived types prevent implicit mixing (Distance_Km + Velocity_Km_S = compile error) |
| **Types** | Distance_Km, Velocity_Km_S, Angle_Radians, Time_Seconds, Gravitational_Parameter |
| **Status** | Approved |

### DEC-004: Exception Strategy
| Field | Value |
|-------|-------|
| **Decision** | Use status returns in SPARK regions, exceptions in user-facing API |
| **Date** | January 2026 |
| **Made By** | Brosgol, Dewar |
| **Rationale** | Status returns enable SPARK proof; exceptions provide convenient error handling for applications |
| **Pattern** | Internal: `procedure Solve(...; Status : out Solver_Status)` → External: `function Solve(...) return Result raises Convergence_Error` |
| **Status** | Approved |

### DEC-005: Folder Structure
| Field | Value |
|-------|-------|
| **Decision** | Reorganize to ada/ (primary), python/ (reference), docs/, reference/, learning/ |
| **Date** | January 2026 |
| **Made By** | Expert Panel (Unanimous) |
| **Rationale** | Clear separation of concerns, Ada as primary implementation |
| **Status** | Approved, pending implementation |

---

## 2. Issue Register

### ISS-001: Kepler Solver Convergence
| Field | Value |
|-------|-------|
| **Issue** | Newton-Raphson may not converge for high-eccentricity orbits |
| **Severity** | Medium |
| **Reported By** | Brosgol |
| **Date** | January 2026 |
| **Status** | Open |
| **Mitigation** | Add Halley's method fallback, bounded iteration count |
| **Assigned To** | Dewar (implementation), Brosgol (verification) |

### ISS-002: Lambert Problem Multi-Revolution
| Field | Value |
|-------|-------|
| **Issue** | Multi-revolution solutions require robust root bracketing |
| **Severity** | Medium |
| **Reported By** | Taft |
| **Date** | January 2026 |
| **Status** | Open |
| **Mitigation** | Use universal variable formulation with Stumpff functions |
| **Assigned To** | Taft (design), Dewar (implementation) |

### ISS-003: Floating-Point Determinism
| Field | Value |
|-------|-------|
| **Issue** | Cross-platform FP results may differ |
| **Severity** | Low |
| **Reported By** | Brosgol |
| **Date** | January 2026 |
| **Status** | Monitoring |
| **Mitigation** | Use strict FP mode, document precision guarantees |
| **Assigned To** | Dewar |

---

## 3. Risk Register

### RISK-001: Certification Scope Creep
| Field | Value |
|-------|-------|
| **Risk** | Attempting full DO-178C Level A before core functionality complete |
| **Probability** | Medium |
| **Impact** | High |
| **Mitigation** | Phase certification: SPARK proofs first, then test coverage, then full certification |
| **Owner** | Brosgol |
| **Status** | Active |

### RISK-002: Performance Regression
| Field | Value |
|-------|-------|
| **Risk** | Ada implementation slower than Python/NumPy |
| **Probability** | Low |
| **Impact** | Medium |
| **Mitigation** | Benchmark critical paths, aggressive inlining, -O3 -gnatn2 |
| **Owner** | Dewar |
| **Status** | Active |

### RISK-003: Dimensional Type Complexity
| Field | Value |
|-------|-------|
| **Risk** | Excessive type conversions reduce readability |
| **Probability** | Medium |
| **Impact** | Low |
| **Mitigation** | Provide convenience functions, document patterns clearly |
| **Owner** | Barnes |
| **Status** | Active |

### RISK-004: SPARK Proof Failures
| Field | Value |
|-------|-------|
| **Risk** | Complex numerical algorithms may not prove easily |
| **Probability** | Medium |
| **Impact** | Medium |
| **Mitigation** | Use loop invariants, add ghost code, simplify where possible |
| **Owner** | Brosgol, Taft |
| **Status** | Active |

---

## 4. Action Register

### ACT-001: Complete Ada Package Implementation
| Field | Value |
|-------|-------|
| **Action** | Implement all packages in ada/src/ |
| **Priority** | High |
| **Assigned To** | Dewar (lead), Taft (contracts) |
| **Due Date** | - |
| **Status** | Complete |
| **Notes** | All core packages implemented including Threebody (CR3BP) |

### ACT-002: Add SPARK Annotations
| Field | Value |
|-------|-------|
| **Action** | Add SPARK_Mode, Global, Depends to pure packages |
| **Priority** | High |
| **Assigned To** | Brosgol (lead), Taft (support) |
| **Due Date** | - |
| **Status** | In Progress |
| **Notes** | SPARK_Mode added to Vectors, Kepler, Threebody. Pre/Post contracts added. |

### ACT-003: Write Comprehensive Tests
| Field | Value |
|-------|-------|
| **Action** | Create AUnit test suite with Hale textbook validation |
| **Priority** | High |
| **Assigned To** | Barnes (cases), Dewar (runner) |
| **Due Date** | - |
| **Status** | Pending |
| **Notes** | Must validate against Chapter 5 examples |

### ACT-004: Document Rationale
| Field | Value |
|-------|-------|
| **Action** | Create docs/rationale/ with design decision explanations |
| **Priority** | Medium |
| **Assigned To** | Barnes (lead) |
| **Due Date** | - |
| **Status** | Pending |
| **Notes** | Follow Ada Rationale document style |

### ACT-005: Reorganize Folder Structure
| Field | Value |
|-------|-------|
| **Action** | Move files per AGENT_COLLABORATION_PROTOCOL.md |
| **Priority** | High |
| **Assigned To** | Current session |
| **Due Date** | Today |
| **Status** | In Progress |
| **Notes** | See approved structure in collaboration protocol |

### ACT-006: Benchmark Performance
| Field | Value |
|-------|-------|
| **Action** | Compare Ada vs Python performance on key algorithms |
| **Priority** | Medium |
| **Assigned To** | Dewar |
| **Due Date** | - |
| **Status** | Pending ACT-001, ACT-003 |
| **Notes** | Focus on Kepler solver, Lambert problem |

---

## 5. Review Register

### REV-001: Initial Python Codebase Review
| Field | Value |
|-------|-------|
| **Date** | January 2026 |
| **Reviewers** | All 5 experts |
| **Subject** | Python three-body-extension implementation |
| **Findings** | Good algorithms, needs type safety, lacks contracts |
| **Recommendations** | 60 specific improvements (see EXPERT_RECOMMENDATIONS.md) |
| **Status** | Complete |

### REV-002: Ada Type System Design
| Field | Value |
|-------|-------|
| **Date** | January 2026 |
| **Reviewers** | Ichbiah, Barnes |
| **Subject** | Dimensional type hierarchy in hale_orbital-types.ads |
| **Findings** | Approved derived types approach |
| **Recommendations** | Add conversion functions for common operations |
| **Status** | Complete |

### REV-003: Agent Persona Files
| Field | Value |
|-------|-------|
| **Date** | January 2026 |
| **Reviewers** | All 5 experts |
| **Subject** | Expanded persona files with founding-era context |
| **Findings** | Approved time-capsule format, Anthropic integration |
| **Recommendations** | None - approved as written |
| **Status** | Complete |

---

## Register Maintenance

- **Decision Register**: Updated when major design choices are made
- **Issue Register**: Updated when bugs or problems are identified
- **Risk Register**: Reviewed weekly, updated as risks evolve
- **Action Register**: Updated daily during active development
- **Review Register**: Updated after each formal review

---

## Quick Reference: Current Priorities

1. **ACT-005**: Reorganize folder structure (Today)
2. **ACT-001**: Complete Ada implementation
3. **ACT-002**: Add SPARK annotations
4. **ACT-003**: Write comprehensive tests
5. **ISS-001**: Fix Kepler convergence issues

---

*Maintained by the Expert Panel per AGENT_COLLABORATION_PROTOCOL.md*

