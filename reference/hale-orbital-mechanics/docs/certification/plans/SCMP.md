# Software Configuration Management Plan (SCMP)

## HALE Orbital Mechanics Library

**Document Number:** HALE-SCMP-001
**Version:** 1.0
**Date:** 2026-01-06
**Classification:** Internal Use
**DO-178C Reference:** Section 11.4

---

## 1. Purpose and Scope

### 1.1 Purpose

This Software Configuration Management Plan (SCMP) establishes the configuration management processes, procedures, and controls for the HALE Orbital Mechanics Library. It ensures that all software configuration items are identified, controlled, and traceable throughout the software lifecycle.

### 1.2 Scope

This plan applies to:
- All Ada source code in `ada/src/`
- All test code in `ada/tests/`
- All documentation in `docs/`
- Build configurations in project files
- CI/CD pipeline configurations
- Third-party dependencies

### 1.3 Applicable Standards

| Standard | Description |
|----------|-------------|
| DO-178C | Software Considerations in Airborne Systems |
| DO-330 | Software Tool Qualification |
| IEEE 828 | Standard for Configuration Management |

---

## 2. Configuration Management Organization

### 2.1 Roles and Responsibilities

| Role | Responsibilities |
|------|------------------|
| **Configuration Manager** | Oversees CM processes, baseline management, audits |
| **Developer** | Creates/modifies CIs, follows CM procedures |
| **Reviewer** | Approves changes, verifies traceability |
| **Build Engineer** | Maintains build system, CI/CD pipeline |
| **QA Engineer** | Audits CM compliance, verifies procedures |

### 2.2 Configuration Control Board (CCB)

The CCB reviews and approves:
- Baseline changes
- Deviations from standards
- Tool changes
- Process changes

**CCB Composition:**
- Configuration Manager (Chair)
- Technical Lead
- QA Representative
- Project Manager (as needed)

---

## 3. Configuration Identification

### 3.1 Configuration Item Types

| CI Type | Prefix | Example |
|---------|--------|---------|
| Source Code | SRC | SRC-KEPLER-001 |
| Test Code | TST | TST-KEPLER-001 |
| Documentation | DOC | DOC-API-001 |
| Build Config | BLD | BLD-GPR-001 |
| Tool | TL | TL-GNAT-001 |

### 3.2 Source Code Configuration Items

| Package | CI Identifier | Files |
|---------|---------------|-------|
| Hale_Orbital (root) | SRC-ROOT-001 | `hale_orbital.ads`, `hale_orbital.adb` |
| Types | SRC-TYPE-001 | `hale_orbital-types.ads` |
| Constants | SRC-CONST-001 | `hale_orbital-constants.ads` |
| Vectors | SRC-VEC-001 | `hale_orbital-vectors.ads/.adb` |
| Matrices | SRC-MAT-001 | `hale_orbital-matrices.ads/.adb` |
| Twobody | SRC-TB-001 | `hale_orbital-twobody.ads/.adb` |
| Elements | SRC-OE-001 | `hale_orbital-elements.ads/.adb` |
| Kepler | SRC-KE-001 | `hale_orbital-kepler.ads/.adb` |
| Stumpff | SRC-ST-001 | `hale_orbital-stumpff.ads/.adb` |
| Lambert | SRC-LB-001 | `hale_orbital-lambert.ads/.adb` |
| Maneuvers | SRC-MAN-001 | `hale_orbital-maneuvers.ads/.adb` |
| Propagation | SRC-PROP-001 | `hale_orbital-propagation.ads/.adb` |
| Threebody | SRC-3B-001 | `hale_orbital-threebody.ads/.adb` |
| Interplanetary | SRC-IP-001 | `hale_orbital-interplanetary.ads/.adb` |

### 3.3 Documentation Configuration Items

| Document | CI Identifier | Location |
|----------|---------------|----------|
| API Reference | DOC-API-001 | `docs/api-reference.md` |
| Architecture | DOC-ARCH-001 | `docs/architecture/` |
| Design Decisions | DOC-DEC-001 | `docs/rationale/DEC-*.md` |
| RTM | DOC-RTM-001 | `docs/certification/rtm.md` |
| SCMP | DOC-SCMP-001 | `docs/certification/plans/SCMP.md` |
| SQAP | DOC-SQAP-001 | `docs/certification/plans/SQAP.md` |
| SDP | DOC-SDP-001 | `docs/certification/plans/SDP.md` |
| SVP | DOC-SVP-001 | `docs/certification/plans/SVP.md` |
| PSAC | DOC-PSAC-001 | `docs/certification/plans/PSAC.md` |

### 3.4 Build Configuration Items

| Item | CI Identifier | File |
|------|---------------|------|
| Main Project | BLD-GPR-001 | `ada/hale_orbital.gpr` |
| Test Project | BLD-GPR-002 | `ada/tests/hale_tests.gpr` |
| CI Pipeline | BLD-CI-001 | `.github/workflows/ada.yml` |

---

## 4. Version Control

### 4.1 Repository Structure

```
hale-orbital-mechanics/
├── ada/
│   ├── src/                    # Source code (SRC-*)
│   ├── tests/                  # Test code (TST-*)
│   ├── hale_orbital.gpr        # Build config (BLD-GPR-001)
│   └── gnatprove/              # SPARK artifacts
├── docs/
│   ├── api-reference.md        # DOC-API-001
│   ├── architecture/           # DOC-ARCH-*
│   ├── rationale/              # DOC-DEC-*
│   └── certification/          # DOC-SCMP/SQAP/etc.
├── .github/
│   └── workflows/              # BLD-CI-*
└── README.md
```

### 4.2 Branching Strategy

| Branch Type | Naming Convention | Purpose | Lifetime |
|-------------|-------------------|---------|----------|
| **main** | `main` | Production baseline | Permanent |
| **develop** | `develop` | Integration branch | Permanent |
| **feature** | `feature/<issue-id>-<description>` | New functionality | Until merged |
| **bugfix** | `bugfix/<issue-id>-<description>` | Bug corrections | Until merged |
| **release** | `release/v<major>.<minor>.<patch>` | Release preparation | Until released |
| **hotfix** | `hotfix/<issue-id>-<description>` | Critical fixes | Until merged |

### 4.3 Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Test additions/modifications
- `build`: Build system changes
- `ci`: CI/CD changes

**Example:**
```
feat(kepler): Add Post contract to Solve_Kepler_Elliptic

Implements ISS-001 from compliance review.
Adds postcondition verifying result satisfies Kepler equation.

Resolves: ISS-001
Tested-by: test_kepler.adb
```

### 4.4 Tagging Convention

| Tag Format | Purpose | Example |
|------------|---------|---------|
| `v<major>.<minor>.<patch>` | Release version | `v0.1.0` |
| `baseline-<name>` | Certification baseline | `baseline-level-c-phase1` |
| `audit-<date>` | Audit checkpoint | `audit-2026-01-15` |

---

## 5. Change Control

### 5.1 Change Request Process

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Submit    │───▶│   Review    │───▶│   Approve   │───▶│  Implement  │
│     CR      │    │   (Tech)    │    │   (CCB)     │    │   & Test    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                                │
┌─────────────┐    ┌─────────────┐    ┌─────────────┐           │
│   Close     │◀───│   Verify    │◀───│   Review    │◀──────────┘
│     CR      │    │   (QA)      │    │   (Code)    │
└─────────────┘    └─────────────┘    └─────────────┘
```

### 5.2 Change Request Template

**CR Number:** CR-YYYY-NNN
**Date Submitted:**
**Submitter:**
**Priority:** Critical / High / Medium / Low
**Classification:** Defect / Enhancement / Documentation

**Description:**
[Detailed description of the change]

**Affected CIs:**
- [ ] SRC-xxx
- [ ] TST-xxx
- [ ] DOC-xxx

**Impact Analysis:**
- Requirements affected:
- Tests affected:
- Documentation affected:

**Verification Method:**
- [ ] Test
- [ ] Review
- [ ] Analysis
- [ ] SPARK Proof

### 5.3 Pull Request Requirements

All changes require:

1. **Code Review**: At least one approved review
2. **Tests Pass**: All CI tests pass
3. **SPARK Clean**: No new SPARK warnings (specifications)
4. **Traceability**: Link to requirement or issue
5. **Documentation**: Updated if API changes

### 5.4 Emergency Change Procedure

For critical defects requiring immediate resolution:

1. Create hotfix branch from `main`
2. Implement minimal fix
3. Expedited CCB review (email/chat)
4. Deploy with post-hoc documentation
5. Full CR created within 24 hours

---

## 6. Baseline Management

### 6.1 Baseline Types

| Baseline | Content | Trigger |
|----------|---------|---------|
| **Functional** | Requirements, RTM | Requirements approval |
| **Design** | Architecture, DEC docs | Design review |
| **Development** | Source code, tests | Feature complete |
| **Certification** | All CIs + evidence | Phase completion |
| **Release** | Deliverable package | Release approval |

### 6.2 Baseline Identification

Format: `BL-<type>-<version>-<date>`

| Baseline ID | Description |
|-------------|-------------|
| `BL-DEV-0.1.0-20260106` | Development baseline v0.1.0 |
| `BL-CERT-C1-20260215` | Level C Phase 1 complete |
| `BL-REL-1.0.0-20260401` | Release 1.0.0 |

### 6.3 Baseline Contents

Each baseline archive includes:

```
baseline-<id>/
├── source/                 # All source code
├── tests/                  # All test code
├── docs/                   # All documentation
├── build/                  # Build configurations
├── evidence/
│   ├── test-results/       # Test execution logs
│   ├── spark-proofs/       # GNATprove output
│   └── coverage/           # Coverage reports
├── manifest.json           # CI list with checksums
└── baseline-report.md      # Baseline description
```

---

## 7. Configuration Status Accounting

### 7.1 Status Reports

| Report | Frequency | Content |
|--------|-----------|---------|
| CI Status | Weekly | Current state of all CIs |
| Change Log | Per release | All changes since last baseline |
| Baseline Report | Per baseline | Baseline contents and changes |
| Audit Report | Per audit | Compliance findings |

### 7.2 Metrics Tracked

- Open change requests by priority
- Change request cycle time
- Baseline frequency
- Test pass rate trend
- SPARK proof coverage

---

## 8. Configuration Audits

### 8.1 Audit Types

| Audit | Purpose | Timing |
|-------|---------|--------|
| **Functional Configuration Audit (FCA)** | Verify CIs match requirements | Before release |
| **Physical Configuration Audit (PCA)** | Verify baseline completeness | Before release |
| **Process Audit** | Verify CM procedures followed | Quarterly |

### 8.2 FCA Checklist

- [ ] All requirements traced to implementation
- [ ] All requirements traced to tests
- [ ] All tests pass
- [ ] SPARK flow analysis clean
- [ ] Coverage targets met

### 8.3 PCA Checklist

- [ ] All CIs identified in manifest
- [ ] All file checksums verified
- [ ] Documentation complete
- [ ] Build reproducible
- [ ] Evidence archived

---

## 9. Tool Environment

### 9.1 Development Tools

| Tool | Version | Purpose | Qualification |
|------|---------|---------|---------------|
| GNAT Pro | 24.x | Ada compiler | TQL-1 (AdaCore) |
| GNATprove | 24.x | SPARK prover | TQL-1 (AdaCore) |
| GNATcoverage | 24.x | Coverage analysis | TQL-1 (AdaCore) |
| gprbuild | 24.x | Build system | TQL-3 |
| Git | 2.x | Version control | N/A |
| GitHub Actions | N/A | CI/CD | N/A |

### 9.2 Tool Configuration

Tool versions pinned in:
- `ada/hale_orbital.gpr` (compiler settings)
- `.github/workflows/ada.yml` (CI environment)
- `docs/certification/tool-versions.md` (reference)

---

## 10. Problem Reporting

### 10.1 Problem Report Categories

| Category | Description | Response Time |
|----------|-------------|---------------|
| **Critical** | Safety impact, blocks certification | 24 hours |
| **High** | Major functionality affected | 72 hours |
| **Medium** | Minor functionality affected | 1 week |
| **Low** | Cosmetic, documentation | 2 weeks |

### 10.2 Problem Report Template

**PR Number:** PR-YYYY-NNN
**Date:**
**Reporter:**
**Category:** Critical / High / Medium / Low
**Status:** Open / Investigating / Fixed / Verified / Closed

**Description:**
[Problem description]

**Steps to Reproduce:**
1.
2.
3.

**Expected Result:**

**Actual Result:**

**Root Cause:**

**Resolution:**

**Affected CIs:**

---

## 11. Archive and Recovery

### 11.1 Archive Requirements

- All baselines archived for product lifetime + 10 years
- Archives stored in redundant locations
- Archive integrity verified annually

### 11.2 Archive Media

| Location | Purpose | Retention |
|----------|---------|-----------|
| Git repository | Primary storage | Permanent |
| Cloud backup | Disaster recovery | Permanent |
| Offline media | Long-term archive | Per baseline |

### 11.3 Recovery Procedure

1. Identify baseline to recover
2. Verify archive integrity (checksums)
3. Extract to clean environment
4. Verify build reproducibility
5. Document recovery in audit log

---

## 12. References

- DO-178C Section 7 (Configuration Management Process)
- DO-178C Section 11.4 (SCMP)
- IEEE 828-2012 (Configuration Management Standard)
- Git Documentation
- AdaCore Tool Documentation

---

## Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-01-06 | | Initial release |

---

## Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Configuration Manager | | | |
| QA Manager | | | |
| Project Manager | | | |
