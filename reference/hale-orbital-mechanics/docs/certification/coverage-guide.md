# Coverage Analysis Guide

**Project:** HALE Orbital Mechanics Library
**Document Version:** 1.0
**Date:** 2026-01-06
**DO-178C Reference:** Section 6.4 - Structural Coverage Analysis
**DAL Target:** Level B (Statement + Decision Coverage)

---

## 1. Introduction

### 1.1 Purpose

This document provides comprehensive guidance for performing structural coverage analysis on the HALE Orbital Mechanics Library. It covers tooling, workflows, and compliance requirements for DO-178C Level B certification.

### 1.2 Coverage Requirements by DAL

| DAL | Statement | Decision | MC/DC |
|-----|-----------|----------|-------|
| Level C | Required | Not Required | Not Required |
| Level B | Required | Required | Not Required |
| Level A | Required | Required | Required |

### 1.3 Definitions

| Term | Definition |
|------|------------|
| Statement Coverage | Every statement in the code has been executed at least once |
| Decision Coverage | Every decision (branch point) has evaluated to both true and false |
| MC/DC | Modified Condition/Decision Coverage - each condition independently affects outcome |
| Uncovered Code | Code not executed during testing (requires justification) |

---

## 2. Tooling Setup

### 2.1 Required Tools

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| GNATcoverage | 23.0+ | Coverage instrumentation and analysis | `alr install gnatcov` |
| GNAT | 12.2+ | Ada compiler | `alr install gnat` |
| gprbuild | 22.0+ | Build tool | Included with GNAT |

### 2.2 Project Configuration

The coverage project file is located at `ada/coverage.gpr`:

```ada
--  Key configuration options
package Coverage_Pkg is
   for Switches use
      ("--level=stmt+decision",     -- Level B coverage
       "--annotate=xcov+",          -- Extended coverage annotations
       "--annotate=html+",          -- HTML report generation
       "--output-dir=coverage/decision");
end Coverage_Pkg;
```

### 2.3 Environment Variables

```bash
# Set coverage level (default: stmt+decision)
export COVERAGE_LEVEL=stmt+decision

# Set output directory
export COVERAGE_OUTPUT=ada/coverage
```

---

## 3. Coverage Workflow

### 3.1 Quick Start

```bash
# Navigate to project root
cd hale-orbital-mechanics

# Run the coverage script (automated workflow)
./scripts/merge_coverage.sh

# View results
open ada/coverage/reports/html/index.html
```

### 3.2 Manual Workflow

#### Step 1: Instrument Source Code

```bash
cd ada
gnatcov instrument -P coverage.gpr \
    --level=stmt+decision \
    --dump-trigger=atexit \
    --dump-filename-prefix=coverage/traces/trace
```

#### Step 2: Build Instrumented Code

```bash
gprbuild -P coverage.gpr -p \
    --src-subdirs=gnatcov-instr \
    --implicit-with=gnatcov_rts_full
```

#### Step 3: Run Tests

```bash
# Run all tests
./bin/test_driver_coverage --suite=all

# Or run specific suites
./bin/test_driver_coverage --suite=vallado
./bin/test_driver_coverage --suite=edge
./bin/test_driver_coverage --suite=negative
./bin/test_driver_coverage --suite=exceptions
./bin/test_driver_coverage --suite=boundaries
./bin/test_driver_coverage --suite=periodic
```

#### Step 4: Generate Coverage Report

```bash
gnatcov coverage -P coverage.gpr \
    --level=stmt+decision \
    --annotate=xcov+ \
    --annotate=html+ \
    coverage/traces/*.srctrace
```

### 3.3 Incremental Coverage

For development, run incremental coverage on specific packages:

```bash
# Instrument specific units
gnatcov instrument -P coverage.gpr \
    --level=stmt+decision \
    --units=hale_orbital.kepler

# Build and run
gprbuild -P coverage.gpr -p
./bin/test_driver_coverage --suite=vallado

# Generate focused report
gnatcov coverage -P coverage.gpr \
    --level=stmt+decision \
    --annotate=html+ \
    --units=hale_orbital.kepler \
    coverage/traces/*.srctrace
```

---

## 4. Understanding Coverage Reports

### 4.1 Coverage Annotations

GNATcoverage uses the following annotations in source listings:

| Symbol | Meaning |
|--------|---------|
| `.` | Covered (statement executed) |
| `-` | Not covered (statement never executed) |
| `+` | Decision True branch taken |
| `!` | Decision partially covered |
| `v` | Both True and False taken |

### 4.2 HTML Report Structure

```
coverage/reports/html/
├── index.html              # Summary page
├── hale_orbital.ads.html   # Per-file coverage
├── hale_orbital.adb.html
├── hale_orbital-kepler.ads.html
├── hale_orbital-kepler.adb.html
└── ...
```

### 4.3 Reading the Summary

The HTML index shows:

| Metric | Target | Interpretation |
|--------|--------|----------------|
| Statement Coverage | 100% | All executable statements run |
| Decision Coverage | 100% | All branches evaluated both ways |
| Covered Lines | Maximize | Lines with `.` or `v` |
| Uncovered Lines | Minimize | Lines with `-` or `!` |

### 4.4 XCov File Format

For CI integration, use `.xcov` files:

```
-- Example: hale_orbital-kepler.adb.xcov
   45 v:  if E < High_Eccentricity_Threshold then
   46 .:     E0 := M + E_Val * Sin (M);
   47 .:  else
   48 .:     E0 := Pi;
   49 .:  end if;
```

---

## 5. Achieving 100% Coverage

### 5.1 Common Coverage Gaps

#### Boolean Parameters

```ada
-- Requires tests with Long_Way = True AND Long_Way = False
function Solve_Lambert (...; Long_Way : Boolean := False) ...
```

**Test Strategy:**
```ada
--  Test short-way transfer
Result_Short := Solve_Lambert (R1, R2, TOF, Mu, Long_Way => False);

--  Test long-way transfer
Result_Long := Solve_Lambert (R1, R2, TOF, Mu, Long_Way => True);
```

#### Threshold Comparisons

```ada
-- Requires tests where E < 0.8 AND E >= 0.8
if E < High_Eccentricity_Threshold then
   --  Low eccentricity path
else
   --  High eccentricity path
end if;
```

**Test Strategy:**
```ada
--  Test low eccentricity (e = 0.5)
E_Low := Solve_Kepler_Elliptic (M, 0.5);

--  Test high eccentricity (e = 0.85)
E_High := Solve_Kepler_Elliptic (M, 0.85);
```

#### Loop Exit Conditions

```ada
loop
   pragma Loop_Invariant (Iter < Max_Iter);
   -- ... iteration ...
   exit when Converged or Iter >= Max_Iter;
end loop;
```

**Test Strategy:**
```ada
--  Normal convergence
E := Solve_Kepler_Elliptic (M, 0.5, Tolerance => 1.0e-12);

--  Force max iterations (tight tolerance)
begin
   E := Solve_Kepler_Elliptic (M, 0.99, Tolerance => 1.0e-20, Max_Iter => 5);
exception
   when Convergence_Error => null;  -- Expected
end;
```

### 5.2 Exception Paths

Every exception raise point must be triggered:

```ada
--  Test case: force Convergence_Error
begin
   --  Pathological case: impossible tolerance
   E := Solve_Kepler_Elliptic (M, 0.999, Tolerance => 0.0, Max_Iter => 1);
   Assert (False, "Should have raised Convergence_Error");
exception
   when Convergence_Error =>
      null;  -- Expected path covered
end;
```

### 5.3 Dead Code Analysis

If code cannot be covered:

1. **Defensive Code:** Document in `coverage-justification.md`
2. **Dead Code:** Remove or justify
3. **Platform-Specific:** Exclude from coverage scope

---

## 6. CI/CD Integration

### 6.1 GitHub Actions Workflow

```yaml
# .github/workflows/coverage.yml
name: Coverage Analysis

on: [push, pull_request]

jobs:
  coverage:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup GNAT
        uses: alire-project/setup-alire@v2

      - name: Install GNATcoverage
        run: alr install gnatcov

      - name: Run Coverage Analysis
        run: |
          cd ada
          ./scripts/merge_coverage.sh

      - name: Upload Coverage Report
        uses: actions/upload-artifact@v3
        with:
          name: coverage-report
          path: ada/coverage/reports/

      - name: Check Coverage Threshold
        run: |
          # Parse coverage from XML and check threshold
          STMT_COV=$(grep -oP 'line-rate="\K[^"]+' ada/coverage/reports/xml/coverage.xml)
          if (( $(echo "$STMT_COV < 0.95" | bc -l) )); then
            echo "Coverage below 95%: $STMT_COV"
            exit 1
          fi
```

### 6.2 Coverage Badges

Add coverage badge to README:

```markdown
![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)
```

### 6.3 Coverage Regression Detection

```bash
# Compare current coverage to baseline
gnatcov coverage-diff \
    coverage/baseline.xml \
    coverage/current.xml \
    --fail-under=100
```

---

## 7. Justifying Uncovered Code

### 7.1 Justification Categories

| Category | Example | Justification |
|----------|---------|---------------|
| Defensive | Division guard never triggers | Input validation prevents this path |
| Platform | OS-specific code | Not applicable to target platform |
| Dead | Legacy support code | Marked for removal in future version |
| Infeasible | Complex precondition | Mathematically impossible to satisfy |

### 7.2 Documentation Template

Create `docs/certification/coverage-justification.md`:

```markdown
# Coverage Justification Log

## Uncovered Statement: hale_orbital-kepler.adb:127

**Code:**
```ada
if Delta > Real'Last then
   raise Constraint_Error;
end if;
```

**Category:** Defensive

**Justification:** This guard is defensive code to catch floating-point
overflow. The precondition on Eccentricity (e < 1.0) and the algorithm
structure guarantee Delta remains bounded. The guard exists as a safety
net per DO-178C guidance on defensive programming.

**Verification:** Static analysis confirms Delta is bounded by the
algorithm's mathematical properties. See proof in spark-report.html.

**Approved By:** [Name], Date: [Date]
```

---

## 8. Troubleshooting

### 8.1 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| No trace files generated | Test crashed | Check test logs, fix failures |
| 0% coverage | Instrumentation failed | Rebuild with `--src-subdirs=gnatcov-instr` |
| Missing units | Units not in scope | Add to `package Units` in coverage.gpr |
| Timeouts | Large codebase | Use `--jobs` for parallelism |

### 8.2 Debug Mode

```bash
# Enable verbose output
gnatcov coverage -P coverage.gpr \
    --level=stmt+decision \
    --verbose \
    coverage/traces/*.srctrace
```

### 8.3 Trace File Inspection

```bash
# Dump trace file contents
gnatcov dump-trace coverage/traces/trace.srctrace
```

---

## 9. References

1. AdaCore. "GNATcoverage User's Guide." 2023.
2. RTCA DO-178C. "Software Considerations in Airborne Systems." 2011.
3. DO-330. "Software Tool Qualification Considerations." 2011.

---

*Document Version: 1.0*
*Last Updated: 2026-01-06*
*Prepared for: DO-178C Level B Certification*
