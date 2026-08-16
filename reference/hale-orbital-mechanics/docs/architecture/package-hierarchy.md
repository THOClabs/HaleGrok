# HALE Orbital Mechanics - Package Hierarchy

*Understanding the library's structure and dependencies*

---

## Overview

The HALE Orbital Mechanics Library follows Ada best practices for package organization with a clear parent-child hierarchy rooted at `Hale_Orbital`.

```
Hale_Orbital (root)
├── Types          -- Core type definitions
├── Constants      -- Physical constants
├── Vectors        -- Vector operations
├── Matrices       -- Matrix operations
├── Twobody        -- Two-body dynamics
├── Elements       -- Orbital element conversions
├── Kepler         -- Kepler equation solver
├── Stumpff        -- Universal variable functions
├── Lambert        -- Lambert problem solver
├── Maneuvers      -- Orbital maneuvers
├── Propagation    -- Numerical integration
├── Interplanetary -- Patched conic transfers
└── Threebody      -- CR3BP dynamics
```

---

## Package Dependency Graph

```
                     ┌─────────────────────┐
                     │    Hale_Orbital     │
                     │      (root)         │
                     └─────────┬───────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
   ┌───────▼───────┐   ┌───────▼───────┐   ┌──────▼──────┐
   │    Types      │   │   Constants   │   │  (others)   │
   │  (pure types) │   │  (pure data)  │   │             │
   └───────┬───────┘   └───────┬───────┘   └──────┬──────┘
           │                   │                  │
           └───────────┬───────┘                  │
                       │                          │
               ┌───────▼───────┐                  │
               │    Vectors    │◄─────────────────┘
               └───────┬───────┘
                       │
               ┌───────▼───────┐
               │   Matrices    │
               └───────┬───────┘
                       │
       ┌───────────────┼───────────────────┐
       │               │                   │
┌──────▼──────┐ ┌──────▼──────┐    ┌───────▼──────┐
│   Twobody   │ │   Stumpff   │    │   Elements   │
└──────┬──────┘ └──────┬──────┘    └───────┬──────┘
       │               │                   │
       │        ┌──────▼──────┐            │
       │        │   Kepler    │            │
       │        └──────┬──────┘            │
       │               │                   │
       │        ┌──────▼──────┐            │
       │        │   Lambert   │◄───────────┘
       │        └──────┬──────┘
       │               │
┌──────▼──────────────▼──────┐
│       Maneuvers            │
└──────┬─────────────────────┘
       │
┌──────▼──────┐      ┌──────────────────┐
│ Propagation │      │  Interplanetary  │
└──────┬──────┘      └────────┬─────────┘
       │                      │
       └──────────┬───────────┘
                  │
          ┌───────▼───────┐
          │   Threebody   │
          │   (CR3BP)     │
          └───────────────┘
```

---

## Package Categories

### Foundation Layer

| Package | Purpose | SPARK | Pure |
|---------|---------|-------|------|
| `Hale_Orbital` | Root package, version info | On | Yes |
| `Hale_Orbital.Types` | Type definitions | On | Yes |
| `Hale_Orbital.Constants` | Physical constants | On | Yes |

These packages have no dependencies and define the fundamental building blocks.

### Mathematical Layer

| Package | Purpose | SPARK | Dependencies |
|---------|---------|-------|--------------|
| `Hale_Orbital.Vectors` | 3D vector operations | Spec: On | Types |
| `Hale_Orbital.Matrices` | 3x3/6x6 matrix operations | Spec: On | Types, Vectors |
| `Hale_Orbital.Stumpff` | Universal variable functions | Spec: On | Types |

These packages provide mathematical primitives used throughout the library.

### Orbital Mechanics Layer

| Package | Purpose | SPARK | Key Functions |
|---------|---------|-------|---------------|
| `Hale_Orbital.Twobody` | Two-body dynamics | Spec: On | Vis_Viva, Orbital_Period |
| `Hale_Orbital.Elements` | Element conversions | Spec: On | State_To_Elements, Elements_To_State |
| `Hale_Orbital.Kepler` | Kepler equation | Spec: On | Solve_Kepler_Elliptic |
| `Hale_Orbital.Lambert` | Lambert problem | Spec: On | Solve_Lambert, Solve_Lambert_Multi |

Core orbital mechanics algorithms from Hale's textbook.

### Applications Layer

| Package | Purpose | SPARK | Key Functions |
|---------|---------|-------|---------------|
| `Hale_Orbital.Maneuvers` | Orbit transfers | Spec: On | Hohmann_Transfer, Bielliptic_Transfer |
| `Hale_Orbital.Propagation` | Numerical integration | Spec: Off | Propagate_RK4, Propagate_RK78 |
| `Hale_Orbital.Interplanetary` | Patched conics | Spec: On | Sphere_Of_Influence, C3_Energy |

Higher-level mission planning capabilities.

### Advanced Dynamics Layer

| Package | Purpose | SPARK | Key Functions |
|---------|---------|-------|---------------|
| `Hale_Orbital.Threebody` | CR3BP dynamics | Spec: On | Jacobi_Constant, Compute_Lagrange_Point |

Extension beyond two-body dynamics for libration point missions.

---

## Design Principles

### 1. Child Package Pattern

All packages are children of `Hale_Orbital`, ensuring:
- Controlled namespace
- Consistent naming (`Hale_Orbital.Vectors.Magnitude`)
- Clear ownership and scope

### 2. Separation of Concerns

```ada
--  Types defines WHAT data looks like
type State_Vector is record
   Position : Position_Vector;
   Velocity : Velocity_Vector;
end record;

--  Vectors defines HOW to manipulate it
function Magnitude (V : Vector_3D) return Real;

--  Twobody defines WHAT IT MEANS orbitally
function Specific_Energy (State : State_Vector; Mu : Gravitational_Parameter) return Specific_Energy;
```

### 3. Dependency Minimization

Each package imports only what it needs:

```ada
--  Kepler only needs Types and Stumpff
with Hale_Orbital.Types; use Hale_Orbital.Types;
with Hale_Orbital.Stumpff;
```

### 4. SPARK Compatibility

Specifications use `SPARK_Mode => On` for verifiable interfaces:

```ada
package Hale_Orbital.Vectors
   with SPARK_Mode => On
is
   function Magnitude (V : Vector_3D) return Real
      with Post => Magnitude'Result >= 0.0;
```

Bodies use `SPARK_Mode => Off` when generic instantiation is required:

```ada
package body Hale_Orbital.Vectors
   with SPARK_Mode => Off  -- Uses Generic_Elementary_Functions
is
```

---

## File Naming Conventions

Following GNAT conventions:

| Package | Spec | Body |
|---------|------|------|
| `Hale_Orbital` | `hale_orbital.ads` | `hale_orbital.adb` |
| `Hale_Orbital.Types` | `hale_orbital-types.ads` | N/A (pure types) |
| `Hale_Orbital.Vectors` | `hale_orbital-vectors.ads` | `hale_orbital-vectors.adb` |

Child packages use hyphen separator: `parent-child.ads`

---

## Import Patterns

### Recommended Usage

```ada
with Hale_Orbital.Types;      use Hale_Orbital.Types;
with Hale_Orbital.Vectors;    use Hale_Orbital.Vectors;
with Hale_Orbital.Twobody;    use Hale_Orbital.Twobody;
with Hale_Orbital.Propagation; use Hale_Orbital.Propagation;

procedure My_Simulation is
   State : State_Vector;
   Model : Two_Body_Model := (Mu => Mu_Earth);
begin
   --  Direct access to types and operations
   State := Propagate_RK4 (Initial, 0.0, 3600.0, 10.0, Model);
end My_Simulation;
```

### Qualified Access (When Preferred)

```ada
with Hale_Orbital.Types;
with Hale_Orbital.Vectors;

procedure My_Simulation is
   V : Hale_Orbital.Types.Vector_3D;
   M : Hale_Orbital.Types.Real;
begin
   M := Hale_Orbital.Vectors.Magnitude (V);
end My_Simulation;
```

---

## Extension Points

### Adding New Packages

New packages should follow the pattern:

```ada
-------------------------------------------------------------------------------
-- Hale_Orbital.NewPackage
-------------------------------------------------------------------------------
package Hale_Orbital.NewPackage
   with SPARK_Mode => On
is
   --  Specification with contracts
end Hale_Orbital.NewPackage;

package body Hale_Orbital.NewPackage
   with SPARK_Mode => Off  -- If using generics
is
   --  Implementation
end Hale_Orbital.NewPackage;
```

### Suggested Extensions

| Extension | Purpose | Dependencies |
|-----------|---------|--------------|
| `Hale_Orbital.Perturbations` | Higher-order perturbations | Propagation |
| `Hale_Orbital.Frames` | Reference frame transformations | Matrices |
| `Hale_Orbital.Time` | Time system conversions | Types |
| `Hale_Orbital.Optimization` | Trajectory optimization | Lambert, Maneuvers |

---

## Related Documents

- [DEC-001: Dimensional Types](../rationale/DEC-001-dimensional-types.md)
- [DEC-002: SPARK Strategy](../rationale/DEC-002-spark-strategy.md)
- [DEC-003: Contract Design](../rationale/DEC-003-contract-design.md)
- [API Reference](../api-reference.md)

---

*"The structure of a program should reflect the structure of the problem."* — Dijkstra
