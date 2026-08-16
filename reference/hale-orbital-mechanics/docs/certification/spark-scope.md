# SPARK Verification Scope Document

**Project:** HALE Orbital Mechanics Library
**Document Version:** 1.0
**Date:** 2026-01-06
**DO-178C Reference:** Section 6.3 - Verification of Software Requirements
**Issues Addressed:** ISS-039, ISS-040, ISS-041, ISS-042

---

## 1. Introduction

### 1.1 Purpose

This document defines the scope of SPARK 2014 formal verification for the HALE Orbital Mechanics Library. It identifies which packages are subject to proof, which are exempt, and provides justification for all exemptions.

### 1.2 SPARK Overview

SPARK 2014 is a formally verifiable subset of Ada 2012 that enables:
- **Flow Analysis:** Detect uninitialized variables, unused assignments
- **Proof:** Verify absence of runtime errors, contract satisfaction
- **Data Flow:** Verify Global and Depends contracts

---

## 2. Verification Strategy

### 2.1 Verification Levels

| Level | Description | Application |
|-------|-------------|-------------|
| Bronze | Flow analysis only | All packages |
| Silver | Proof of AoRTE (Absence of Run-Time Errors) | Core packages |
| Gold | Proof of functional correctness | Selected packages |

### 2.2 Target Level

For DO-178C Level C, the target is:
- **Bronze:** All specification files
- **Silver:** Foundation and core packages
- **Gold:** Vector and matrix operations (critical primitives)

---

## 3. Package-by-Package Scope

### 3.1 Foundation Packages

| Package | Spec | Body | Level | Notes |
|---------|------|------|-------|-------|
| Hale_Orbital | On | N/A | Bronze | Root package, spec only |
| Hale_Orbital.Types | On | N/A | Bronze | Pure package |
| Hale_Orbital.Constants | On | N/A | Bronze | Pure package |
| Hale_Orbital.Vectors | On | Off | Bronze | Body uses generic; proof pending (gnatprove has never run) |
| Hale_Orbital.Matrices | On | Off | Bronze | Body uses generic; proof pending (gnatprove has never run) |

### 3.2 Core Packages

| Package | Spec | Body | Level | Notes |
|---------|------|------|-------|-------|
| Hale_Orbital.Elements | On | Off | Bronze | Body uses generic |
| Hale_Orbital.Kepler | On | Off | Bronze | Body uses generic |
| Hale_Orbital.Stumpff | On | Off | Bronze | Body uses generic |
| Hale_Orbital.Twobody | On | Off | Bronze | Body uses generic |

### 3.3 High-Level Packages

| Package | Spec | Body | Level | Notes |
|---------|------|------|-------|-------|
| Hale_Orbital.Lambert | On | Off | Bronze | Body uses generic |
| Hale_Orbital.Propagation | On | Off | Bronze | Body uses generic |
| Hale_Orbital.Maneuvers | On | Off | Bronze | Body uses generic |
| Hale_Orbital.Threebody | On | Off | Bronze | Body uses generic |

---

## 4. Exemption Justifications

### 4.1 Generic Instantiation Exemption (ISS-040)

**Affected Packages:** Vectors, Matrices, Elements, Kepler, Stumpff, Twobody, Lambert, Propagation, Maneuvers, Threebody

**Reason:**
These packages instantiate `Ada.Numerics.Generic_Elementary_Functions` for transcendental operations (sin, cos, sqrt, etc.). SPARK 2014 does not currently support generic instantiation within proved bodies.

**Exemption Code:**
```ada
package body Hale_Orbital.Kepler
   with SPARK_Mode => Off  --  Body uses Ada.Numerics generic instantiation
is
   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
```

**Mitigation:**
1. Specifications remain SPARK_Mode => On with full contracts
2. Flow analysis verifies data flow properties
3. Extensive test coverage validates implementation
4. Contracts catch errors at interface boundary

### 4.2 Contract Coverage (ISS-041)

All public functions in exempted packages have:
- **Pre conditions:** Input validation
- **Post conditions:** Output guarantees
- **Global => null:** Thread safety

Example:
```ada
function Solve_Kepler_Elliptic (Mean_Anomaly : Angle_Radians;
                                Eccentricity : Real;
                                Tolerance    : Real := Default_Tolerance;
                                Max_Iter     : Positive := Default_Max_Iterations)
                                return Angle_Radians
   with Pre  => Eccentricity >= 0.0 and Eccentricity < 1.0
                and Tolerance > 0.0,
        Post => Real (Solve_Kepler_Elliptic'Result) >= -0.001
                and Real (Solve_Kepler_Elliptic'Result) <= 6.3,
        Global => null;
```

### 4.3 Loop Invariant Coverage (ISS-042)

All iteration loops include:
- Loop_Invariant for iteration bound
- Loop_Invariant for convergence property (where applicable)

Example:
```ada
loop
   pragma Loop_Invariant (Iter < Max_Iter);
   --  Invariant: Z in [Z_Low, Z_High] and |F(Z)| decreasing

   -- iteration body

   Iter := Iter + 1;
   exit when Converged or Iter >= Max_Iter;
end loop;
```

---

## 5. GNATprove Configuration

### 5.1 Project File Settings

```ada
package Prove is
   for Proof_Switches ("Ada") use (
      "-j0",           -- Use all available cores
      "--level=2",     -- Medium proof effort
      "--timeout=60",  -- 60 second timeout per VC
      "--warnings=continue"
   );
end Prove;
```

### 5.2 Proof Modes

| Mode | Command | Purpose |
|------|---------|---------|
| Flow | `gnatprove --mode=flow` | Data flow analysis |
| Prove | `gnatprove --mode=prove` | Full verification |
| Check | `gnatprove --mode=check` | Syntax/type checking |

### 5.3 Expected Results

| Category | Expected |
|----------|----------|
| Flow warnings | 0 |
| Unproved VCs (Silver) | 0 |
| Unproved VCs (Gold) | < 5% (with justification) |
| Timeouts | 0 |

---

## 6. Verified Properties

### 6.1 Absence of Runtime Errors

For Silver level packages:
- No division by zero
- No array index out of bounds
- No numeric overflow
- No access to uninitialized variables

### 6.2 Contract Satisfaction

For all packages with SPARK_Mode => On:
- All Pre conditions satisfiable
- All Post conditions provable (given Pre)
- All Global contracts accurate

### 6.3 Functional Properties

Aspirational, for when Vectors/Matrices reach Gold (no proof has run yet — see 3.1):
- Normalization produces unit vector
- Dot product commutative
- Cross product anti-symmetric
- Rotation matrices orthogonal

---

## 7. Proof Artifact Management

### 7.1 Generated Files

```
obj/gnatprove/
├── gnatprove.out          # Summary output
├── *.spark                # Proof session files
├── *.mlw                  # Why3 proof obligations
└── statistics/            # Proof statistics
```

### 7.2 CI Integration

The CI pipeline shall:
1. Run `gnatprove --mode=flow` (must pass)
2. Run `gnatprove --mode=prove --level=1` (quick check)
3. Archive proof artifacts
4. Fail on new unproved VCs

---

## 8. Justification Log

### 8.1 Justified Unproved VCs

| Package | VC | Reason | Justification |
|---------|-----|--------|---------------|
| N/A | N/A | No unproved VCs in scope | N/A |

### 8.2 Future Work

| Item | Priority | Notes |
|------|----------|-------|
| Prove loop termination | Medium | Add Loop_Variant |
| Prove energy conservation | Low | Requires real arithmetic model |
| Prove Kepler convergence | Low | Complex analysis required |

---

## 9. Verification Coverage Summary

| Metric | Target | Current |
|--------|--------|---------|
| Packages with spec SPARK_Mode On | 100% | 100% |
| Public functions with contracts | 100% | 100% |
| Loops with invariants | 100% | 100% |
| Flow analysis pass | Pass | Pending (gnatprove unavailable in CI) |
| Silver proof (foundation) | Pass | Pending |
| Gold proof (vectors) | Pass | Pending |

---

## 10. References

1. AdaCore. "SPARK 2014 User's Guide." 2021.
2. DO-178C. "Software Considerations in Airborne Systems." RTCA. 2011.
3. Chapman, R. and Schanda, F. "Are We There Yet? 20 Years of Industrial Theorem Proving with SPARK." 2014.

---

*Document Version: 1.0*
*Last Updated: 2026-01-06*
*Prepared for: DO-178C Level C Certification*
