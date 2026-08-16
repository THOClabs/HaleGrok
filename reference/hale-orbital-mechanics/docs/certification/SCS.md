# Software Code Standards (SCS)

**Project:** HALE Orbital Mechanics Library
**Document Version:** 1.0
**Date:** 2026-01-06
**DO-178C Reference:** Section 5.3 - Software Coding Standards
**DAL:** Level C (Major Failure Condition)

---

## 1. Introduction

### 1.1 Purpose

This Software Code Standards (SCS) document defines the coding conventions, style guidelines, and quality requirements for the HALE Orbital Mechanics Library source code.

### 1.2 Scope

These standards apply to all Ada source code in the HALE library, including:
- Package specifications (.ads files)
- Package bodies (.adb files)
- Test code

### 1.3 Language Standard

- **Language:** Ada 2012
- **Compiler:** GNAT Community Edition 2021 or later
- **SPARK:** SPARK 2014 subset for verified packages

---

## 2. Naming Conventions

### 2.1 Package Names

- Use `Hale_Orbital` as the root package prefix
- Use underscores to separate words: `Hale_Orbital.Lambert`
- Child packages reflect functionality: `Hale_Orbital.Kepler`

### 2.2 Type Names

| Category | Convention | Example |
|----------|------------|---------|
| Scalar types | Mixed_Case | `Distance_Km`, `Real` |
| Record types | Mixed_Case | `Orbital_Elements`, `State_Vector` |
| Array types | Mixed_Case_Array | `Lambert_Solution_Array` |
| Enum types | Mixed_Case | `Orbit_Type`, `Transfer_Direction` |

### 2.3 Subprogram Names

| Category | Convention | Example |
|----------|------------|---------|
| Functions | Mixed_Case verb/noun | `Solve_Kepler_Elliptic` |
| Procedures | Mixed_Case verb | `Propagate_State` |
| Predicates | Is_/Has_ prefix | `Is_Degenerate_Transfer` |
| Getters | Get_ prefix (if needed) | `Get_Transfer_Elements` |

### 2.4 Variable and Constant Names

| Category | Convention | Example |
|----------|------------|---------|
| Local variables | Mixed_Case | `Cos_Dnu`, `R1_Mag` |
| Constants | Mixed_Case | `Default_Tolerance` |
| Loop indices | Single letter or short | `I`, `J`, `Iter` |
| Parameters | Mixed_Case | `Mean_Anomaly`, `Eccentricity` |

### 2.5 Exception Names

- Use `_Error` suffix: `Convergence_Error`, `Invalid_Orbit`

---

## 3. Code Layout

### 3.1 File Structure

```ada
-------------------------------------------------------------------------------
-- Package Name - Brief Description
-------------------------------------------------------------------------------
-- Longer description of package purpose and functionality.
-- Reference to textbook or algorithm source.
--
-- SPARK Status: On/Off with reason
-------------------------------------------------------------------------------

with Dependency_1;   use Dependency_1;
with Dependency_2;   use Dependency_2;

package Package_Name
   with SPARK_Mode => On  -- or Off with justification
is
   -- Public declarations
end Package_Name;
```

### 3.2 Indentation

- Use 3 spaces per indentation level (no tabs)
- Align continuation lines with logical grouping:

```ada
function Solve_Lambert (R1        : Position_Vector;
                        R2        : Position_Vector;
                        Tof       : Time_Seconds;
                        Mu        : Gravitational_Parameter;
                        Long_Way  : Boolean := False;
                        Tolerance : Real := Default_Tolerance)
                        return Lambert_Result;
```

### 3.3 Line Length

- Maximum 80 characters per line preferred
- Maximum 100 characters absolute limit
- Break long lines at logical points

### 3.4 Blank Lines

- Two blank lines between major sections
- One blank line between subprograms
- No trailing blank lines at end of file

---

## 4. Comments

### 4.1 File Headers

Every source file shall begin with a header block:

```ada
-------------------------------------------------------------------------------
-- HALE Orbital Mechanics - Package Name
-------------------------------------------------------------------------------
-- Description of package purpose and contents.
--
-- Reference: Author (Year). Book Title. Publisher. Chapter X.
--
-- SPARK Status: On/Off
-- DO-178C: Requirement references
-------------------------------------------------------------------------------
```

### 4.2 Subprogram Comments

Document all public subprograms:

```ada
--  Solve the elliptic Kepler equation E - e*sin(E) = M
--  Uses Newton-Raphson iteration with convergence guard for high-e
--  Reference: Vallado 4th Ed., Algorithm 2
--  RTM: HLR-1A-001
function Solve_Kepler_Elliptic (...) return Angle_Radians;
```

### 4.3 Inline Comments

- Use `--` style (never `/* */`)
- Comment non-obvious logic
- Avoid obvious comments ("Increment i")

```ada
--  Clamp cosine to [-1, 1] for numerical safety
if Cos_Dnu > 1.0 then
   Cos_Dnu := 1.0;
elsif Cos_Dnu < -1.0 then
   Cos_Dnu := -1.0;
end if;
```

### 4.4 TODO Comments

Mark incomplete work clearly:

```ada
--  TODO(ISS-042): Add SPARK proof for this loop invariant
```

---

## 5. SPARK Annotations

### 5.1 Contract Aspects

All public functions shall have:

```ada
function Example (X : Input_Type) return Output_Type
   with Pre    => <input validation>,
        Post   => <output guarantees>,
        Global => null;  -- Thread safety
```

### 5.2 Loop Invariants

Iteration loops shall have:

```ada
loop
   pragma Loop_Invariant (Iter < Max_Iter);
   pragma Loop_Invariant (<convergence property>);
   -- loop body
end loop;
```

### 5.3 Ghost Code

Use ghost entities for proof-only code:

```ada
function Valid_Elements (E : Orbital_Elements) return Boolean
   with Ghost;
```

### 5.4 SPARK_Mode Pragma

- Spec: `with SPARK_Mode => On` when contracts are complete
- Body: `with SPARK_Mode => Off` when generic instantiation used

Justification comment required for Off:

```ada
package body Hale_Orbital.Kepler
   with SPARK_Mode => Off  --  Body uses Ada.Numerics generic instantiation
is
```

---

## 6. Numeric Programming

### 6.1 Magic Number Prohibition

**DO NOT:**
```ada
if abs (A) < 0.00001 then  -- Magic number!
```

**DO:**
```ada
if abs (A) < Small_Threshold then  -- Named constant from Types
```

### 6.2 Floating-Point Comparisons

Never use exact equality for floating-point:

**DO NOT:**
```ada
if E = 1.0 then  -- Exact comparison!
```

**DO:**
```ada
if E > 1.0 - Parabolic_Threshold then  -- Threshold comparison
```

### 6.3 Division Safety

Always guard division:

```ada
if abs (Denominator) > Small_Threshold then
   Result := Numerator / Denominator;
else
   raise Singularity_Error with "Division by near-zero value";
end if;
```

### 6.4 Overflow Prevention

Use intermediate variables for complex expressions:

```ada
--  Avoid: Result := (A * B * C) / (D * E * F);
Numerator := A * B;
Numerator := Numerator * C;
Denominator := D * E;
Denominator := Denominator * F;
Result := Numerator / Denominator;
```

---

## 7. Error Handling

### 7.1 Exception Usage

| Exception | Use Case |
|-----------|----------|
| `Convergence_Error` | Solver exceeds max iterations |
| `Invalid_Orbit` | Physically impossible parameters |
| `Singularity_Error` | Geometric singularity (e.g., 180° transfer) |
| `Physical_Error` | Conservation law violation |

### 7.2 Exception Messages

Include diagnostic information:

```ada
raise Convergence_Error with
   "Kepler solver failed after" & Natural'Image (Max_Iter) &
   " iterations, residual = " & Real'Image (Residual);
```

### 7.3 Pre-condition Validation

Prefer Pre conditions over runtime checks:

```ada
function Circular_Velocity (R : Distance_Km; Mu : Gravitational_Parameter)
   return Velocity_Km_S
   with Pre => Real (R) > 0.0 and Real (Mu) > 0.0;
```

---

## 8. Type Safety

### 8.1 Dimensional Types

Use appropriate dimensional type:

**DO NOT:**
```ada
function Velocity (Distance : Real; Time : Real) return Real;
```

**DO:**
```ada
function Velocity (Distance : Distance_Km; Time : Time_Seconds)
   return Velocity_Km_S;
```

### 8.2 Type Conversions

Explicit conversions between dimensional types:

```ada
A_Real : constant Real := Real (A_Distance);  -- Explicit
```

### 8.3 Subtype Constraints

Use subtypes for range constraints:

```ada
subtype Valid_Eccentricity is Real range 0.0 .. Real'Last;
```

---

## 9. Testing Standards

### 9.1 Test Naming

```ada
procedure Test_<Category>_<Specific>
--  Example: Test_Kepler_Edge_Cases
```

### 9.2 Test Documentation

Each test procedure shall include:

```ada
--  Test: <brief description>
--  RTM: <requirement ID>
--  Expected: <expected behavior>
procedure Test_Example is
```

### 9.3 Tolerance Usage

Use named constants for tolerances:

```ada
Position_Tolerance : constant Real := 1.0e-6;   -- 1 mm
--  Justification: See tolerance-justification.md Section 4.1
```

---

## 10. Prohibited Constructs

### 10.1 Never Use

| Construct | Reason |
|-----------|--------|
| `goto` | Unstructured control flow |
| Global variables | Thread safety, SPARK incompatible |
| `access` types in public API | Memory safety |
| Floating-point `=` | Inexact representation |
| Unchecked_Conversion | Type safety bypass |
| Magic numbers | Maintainability |

### 10.2 Use With Caution

| Construct | Guidance |
|-----------|----------|
| Generic instantiation | Document SPARK_Mode Off |
| Exception handlers | Only at boundaries |
| Recursion | Ensure termination proof |

---

## 11. Configuration Management

### 11.1 File Organization

```
ada/
├── src/           # Source code
│   ├── hale_orbital.ads
│   ├── hale_orbital-types.ads
│   ├── hale_orbital-*.ads/adb
│   └── ...
├── tests/         # Test code
│   ├── hale_tests.ads
│   ├── hale_tests-*.ads/adb
│   └── ...
└── hale_orbital.gpr  # GNAT project file
```

### 11.2 Version Control

- All source under Git version control
- Meaningful commit messages referencing issues
- No generated files committed

---

## 12. Compliance Checklist

Before code review, verify:

- [ ] Package header with description and references
- [ ] All public subprograms have contracts (Pre, Post, Global)
- [ ] No magic numbers (use named constants)
- [ ] No exact floating-point comparisons
- [ ] Division guarded against zero
- [ ] Exception messages include diagnostics
- [ ] SPARK_Mode declared with justification
- [ ] RTM requirement IDs in comments
- [ ] Test procedures for all public functions

---

*Document Version: 1.0*
*Last Updated: 2026-01-06*
*Prepared for: DO-178C Level C Certification*
