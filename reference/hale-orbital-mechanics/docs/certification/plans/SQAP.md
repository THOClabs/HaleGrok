# Software Quality Assurance Plan (SQAP)

## HALE Orbital Mechanics Library

**Document Number:** HALE-SQAP-001
**Version:** 1.0
**Date:** 2026-01-06
**Classification:** Internal Use
**DO-178C Reference:** Section 11.5

---

## 1. Purpose and Scope

### 1.1 Purpose

This Software Quality Assurance Plan (SQAP) defines the quality assurance activities, processes, and procedures that ensure the HALE Orbital Mechanics Library is developed in compliance with DO-178C objectives for the target Design Assurance Level (DAL C).

### 1.2 Scope

This plan applies to:
- All software development activities
- All verification activities
- All configuration management activities
- All documentation activities
- Supplier/subcontractor activities (if applicable)

### 1.3 Quality Objectives

| Objective | Target | Metric |
|-----------|--------|--------|
| Requirements Coverage | 100% | All requirements tested |
| Statement Coverage | 100% | GNATcoverage report |
| SPARK Flow Clean | 100% | No flow errors |
| Contract Coverage | 100% | All public APIs |
| Review Coverage | 100% | All changes reviewed |

---

## 2. Organization and Independence

### 2.1 QA Organization

```
┌─────────────────────┐
│   Project Manager   │
└──────────┬──────────┘
           │
    ┌──────┴──────┐
    │             │
┌───┴───┐    ┌───┴───┐
│  Dev  │    │  QA   │◀── Independent
│ Team  │    │ Team  │    Authority
└───────┘    └───────┘
```

### 2.2 QA Independence

Per DO-178C Section 5.4, QA maintains independence through:

1. **Organizational Independence**: QA reports to Project Manager, not Development Lead
2. **Technical Independence**: QA may review but not modify development work products
3. **Financial Independence**: QA budget separate from development
4. **Authority**: QA has authority to stop releases for quality issues

### 2.3 QA Responsibilities

| Activity | QA Role |
|----------|---------|
| Process Definition | Define and maintain QA processes |
| Process Audits | Verify processes are followed |
| Product Audits | Verify work products are complete and correct |
| Compliance Verification | Ensure DO-178C compliance |
| Problem Reporting | Track and escalate quality issues |
| Metrics Collection | Gather and analyze quality metrics |
| Supplier Oversight | Audit supplier quality (if applicable) |

---

## 3. Software Life Cycle Oversight

### 3.1 Life Cycle Phases

| Phase | QA Activities |
|-------|---------------|
| **Planning** | Review plans (SDP, SVP, SCMP, SQAP) |
| **Requirements** | Review HLR/LLR for completeness |
| **Design** | Review architecture and design |
| **Implementation** | Code review participation |
| **Verification** | Review test procedures and results |
| **Configuration** | Audit CM compliance |
| **Certification** | Compile certification evidence |

### 3.2 Phase Entry/Exit Criteria

#### Requirements Phase

**Entry:**
- [ ] SDP approved
- [ ] SVP approved
- [ ] Requirements sources identified

**Exit:**
- [ ] All HLRs documented
- [ ] All HLRs traceable to source
- [ ] HLR review complete
- [ ] RTM updated

#### Design Phase

**Entry:**
- [ ] Requirements phase complete
- [ ] Architecture approach approved

**Exit:**
- [ ] Architecture documented
- [ ] LLRs defined (contracts)
- [ ] Design review complete
- [ ] RTM updated with LLRs

#### Implementation Phase

**Entry:**
- [ ] Design phase complete
- [ ] Coding standards available

**Exit:**
- [ ] All code implemented
- [ ] Code reviews complete
- [ ] SPARK annotations complete
- [ ] Unit tests pass

#### Verification Phase

**Entry:**
- [ ] Implementation phase complete
- [ ] Test procedures ready

**Exit:**
- [ ] All tests pass
- [ ] Coverage targets met
- [ ] SPARK flow clean
- [ ] Verification report complete

---

## 4. Review and Audit Procedures

### 4.1 Review Types

| Review Type | Purpose | Participants |
|-------------|---------|--------------|
| **Requirements Review** | Verify completeness, correctness | Tech Lead, QA, Stakeholders |
| **Design Review** | Verify architecture meets requirements | Tech Lead, QA, Developers |
| **Code Review** | Verify code quality and standards | Developers, QA |
| **Test Review** | Verify test adequacy | Test Lead, QA, Developers |
| **Documentation Review** | Verify completeness and accuracy | Tech Lead, QA |

### 4.2 Code Review Checklist

#### Functional Correctness
- [ ] Logic implements requirements correctly
- [ ] Edge cases handled
- [ ] Error conditions handled
- [ ] Algorithm matches design

#### SPARK/Contracts
- [ ] Pre-conditions complete and correct
- [ ] Post-conditions meaningful (not trivial)
- [ ] Global annotations present
- [ ] Depends clauses correct (procedures)

#### Coding Standards
- [ ] Naming conventions followed
- [ ] GNAT warnings clean (`-gnatwa`)
- [ ] Style checks pass (`-gnatyg`)
- [ ] No magic numbers (use constants)

#### Numerical Considerations
- [ ] Division by zero guarded
- [ ] Overflow considered
- [ ] Tolerance documented
- [ ] Threshold values justified

#### Traceability
- [ ] Requirement ID referenced
- [ ] Test case identified
- [ ] RTM updated

### 4.3 Audit Schedule

| Audit Type | Frequency | Scope |
|------------|-----------|-------|
| Process Audit | Quarterly | Development, CM, Verification |
| Product Audit | Per baseline | All CIs in baseline |
| Compliance Audit | Per phase | DO-178C objectives |
| Supplier Audit | Annual | Supplier processes (if applicable) |

### 4.4 Audit Procedure

1. **Plan**: Define scope, schedule, checklist
2. **Notify**: Inform auditees 1 week in advance
3. **Execute**: Conduct audit, collect evidence
4. **Report**: Document findings, recommendations
5. **Follow-up**: Verify corrective actions
6. **Close**: Archive audit records

---

## 5. Problem Reporting and Corrective Action

### 5.1 Problem Report Process

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Detect  │───▶│ Report  │───▶│ Analyze │───▶│ Resolve │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
                                                   │
┌─────────┐    ┌─────────┐    ┌─────────┐         │
│  Close  │◀───│ Verify  │◀───│ Review  │◀────────┘
└─────────┘    └─────────┘    └─────────┘
```

### 5.2 Problem Severity Classification

| Severity | Definition | Response | Escalation |
|----------|------------|----------|------------|
| **1-Critical** | Safety impact, certification blocker | 24 hrs | Immediate PM/CCB |
| **2-High** | Major functionality broken | 72 hrs | PM weekly |
| **3-Medium** | Minor functionality affected | 1 week | QA review |
| **4-Low** | Cosmetic, suggestion | 2 weeks | Normal queue |

### 5.3 Corrective Action Requirements

For Severity 1-2 problems:

1. **Root Cause Analysis**: Identify underlying cause
2. **Corrective Action**: Fix the immediate problem
3. **Preventive Action**: Prevent recurrence
4. **Effectiveness Review**: Verify actions worked

### 5.4 Problem Metrics

| Metric | Formula | Target |
|--------|---------|--------|
| Mean Time to Resolution | Avg(Close - Open) | < 5 days |
| Escape Rate | Post-release defects / Total defects | < 5% |
| Reopen Rate | Reopened / Closed | < 10% |

---

## 6. Compliance Verification

### 6.1 DO-178C Objectives Tracking

QA maintains compliance matrix tracking:

| Table | Objectives | Applicable to DAL C |
|-------|------------|---------------------|
| A-1 | Planning Process | 6 objectives |
| A-2 | Development Process | 7 objectives |
| A-3 | HLR Verification | 5 objectives |
| A-4 | LLR Verification | 3 objectives |
| A-5 | Source Code Verification | 6 objectives |
| A-6 | Testing | 5 objectives |
| A-7 | Structural Coverage | 5 objectives |

### 6.2 Compliance Evidence

For each objective, QA verifies:

- [ ] Activity performed per plan
- [ ] Work product created
- [ ] Work product reviewed
- [ ] Evidence archived
- [ ] Traceability established

### 6.3 Compliance Reporting

| Report | Content | Frequency |
|--------|---------|-----------|
| Objectives Status | % complete per table | Weekly |
| Compliance Dashboard | All tables summary | Per phase |
| Final Compliance Report | Full DO-178C matrix | Certification |

---

## 7. Supplier Quality Assurance

### 7.1 Supplier Categories

| Category | Example | QA Requirements |
|----------|---------|-----------------|
| **Tool Supplier** | AdaCore (GNAT) | Tool qualification data |
| **COTS Library** | N/A currently | COTS assessment |
| **Subcontractor** | N/A currently | Full QA oversight |

### 7.2 Tool Qualification

For qualification credit (DO-330):

| Tool | TQL | Qualification Evidence |
|------|-----|------------------------|
| GNATprove | TQL-1 | AdaCore qualification kit |
| GNATcoverage | TQL-1 | AdaCore qualification kit |
| GNAT Compiler | TQL-1 | AdaCore qualification kit |

---

## 8. Records and Documentation

### 8.1 QA Records

| Record Type | Retention | Location |
|-------------|-----------|----------|
| Review Records | Product life + 10 years | `docs/certification/reviews/` |
| Audit Records | Product life + 10 years | `docs/certification/audits/` |
| Problem Reports | Product life + 10 years | GitHub Issues + Archive |
| Metrics Reports | Product life + 10 years | `docs/certification/metrics/` |

### 8.2 Record Requirements

All QA records must include:
- Date
- Participants
- Findings/Results
- Actions required
- Sign-off

---

## 9. Training

### 9.1 Required Training

| Role | Training Required |
|------|-------------------|
| All Team | DO-178C Overview |
| Developers | SPARK/Ada, Coding Standards |
| QA | DO-178C QA Processes |
| Reviewers | Review Procedures |

### 9.2 Training Records

Training completion tracked in:
- Individual training logs
- Project training matrix
- Qualification records

---

## 10. Metrics and Reporting

### 10.1 Quality Metrics

| Metric | Definition | Collection | Target |
|--------|------------|------------|--------|
| Defect Density | Defects / KLOC | Per release | < 1.0 |
| Review Coverage | Reviewed LOC / Total LOC | Per phase | 100% |
| Test Coverage | Covered stmts / Total stmts | Per build | 100% |
| First Pass Yield | Items passing first review | Per review | > 90% |
| On-Time Delivery | Milestones on time | Per phase | > 90% |

### 10.2 Reporting Schedule

| Report | Audience | Frequency |
|--------|----------|-----------|
| Weekly Status | Team | Weekly |
| Quality Dashboard | PM | Bi-weekly |
| Phase Summary | Stakeholders | Per phase |
| Certification Package | DER | Certification |

---

## 11. Non-Conformance Process

### 11.1 Non-Conformance Categories

| Category | Example | Disposition |
|----------|---------|-------------|
| **Process** | Procedure not followed | Corrective action |
| **Product** | Work product incomplete | Rework |
| **Deviation** | Intentional departure | CCB approval |
| **Waiver** | Requirement not met | CCB + DER approval |

### 11.2 Disposition Options

1. **Rework**: Correct the non-conformance
2. **Accept As-Is**: Document justification
3. **Deviation**: Approve alternate approach
4. **Reject**: Discard and restart

### 11.3 Deviation/Waiver Process

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Request │───▶│ Analyze │───▶│   CCB   │───▶│Document │
│         │    │ Impact  │    │ Approve │    │         │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
```

For certification deviations, DER concurrence required.

---

## 12. Continuous Improvement

### 12.1 Lessons Learned

After each phase:
1. Conduct retrospective
2. Document lessons learned
3. Update processes as needed
4. Share with team

### 12.2 Process Improvement

QA maintains process improvement log:
- Issue identified
- Root cause
- Proposed improvement
- Implementation status
- Effectiveness measure

---

## 13. References

- DO-178C Section 5 (Software Quality Assurance)
- DO-178C Section 11.5 (SQAP)
- IEEE 730 (Software Quality Assurance)
- AS9100 (Aerospace Quality Management)

---

## Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-01-06 | | Initial release |

---

## Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| QA Manager | | | |
| Project Manager | | | |
| Configuration Manager | | | |
