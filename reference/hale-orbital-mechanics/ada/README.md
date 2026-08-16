# HALE Orbital Mechanics - Ada Implementation

This directory contains the Ada implementation of the HALE Orbital Mechanics library.

## Status: Core Implementation Complete

The following modules have been implemented:

| Module | Status | Description |
|--------|--------|-------------|
| `hale_orbital` | Complete | Root package |
| `hale_orbital-types` | Complete | Core type definitions |
| `hale_orbital-constants` | Complete | Physical constants (Hale Appendix B) |
| `hale_orbital-vectors` | Complete | 3D vector operations |
| `hale_orbital-matrices` | Complete | Matrix operations and rotations |
| `hale_orbital-twobody` | Complete | Two-body dynamics (vis-viva, energy, momentum) |
| `hale_orbital-elements` | Complete | Orbital element conversions |
| `hale_orbital-kepler` | Complete | Kepler's equation solvers |
| `hale_orbital-lambert` | Complete | Lambert problem solver |
| `hale_orbital-maneuvers` | Complete | Hohmann, bi-elliptic, plane change |

## Prerequisites

- GNAT Community Edition 2021+ or GNAT Pro
- Ada 2012 compatible compiler

## Directory Structure

```
ada_conversion/
├── hale_orbital.gpr              -- Main GNAT project file
├── CONVERSION_PLAN.md            -- Detailed conversion plan
├── README.md                     -- This file
├── src/
│   ├── hale_orbital.ads/adb      -- Root package
│   ├── hale_orbital-types.ads    -- Core type definitions
│   ├── hale_orbital-constants.ads -- Physical constants
│   ├── hale_orbital-vectors.ads/adb   -- Vector operations
│   ├── hale_orbital-matrices.ads/adb  -- Matrix operations
│   ├── hale_orbital-twobody.ads/adb   -- Two-body dynamics
│   ├── hale_orbital-elements.ads/adb  -- Orbital elements
│   ├── hale_orbital-kepler.ads/adb    -- Kepler solvers
│   ├── hale_orbital-lambert.ads/adb   -- Lambert solver
│   ├── hale_orbital-maneuvers.ads/adb -- Orbital maneuvers
│   └── threebody/                -- Three-body extension (planned)
├── tests/
│   ├── hale_tests.gpr            -- Test project file
│   └── run_tests.adb             -- Test runner
├── obj/                          -- Object files (generated)
├── lib/                          -- Library output (generated)
└── bin/                          -- Executables (generated)
```

## Building

```bash
# Build the library (debug mode)
gprbuild -P hale_orbital.gpr

# Build the library (release mode)
gprbuild -P hale_orbital.gpr -XBUILD_MODE=release

# Build and run tests
gprbuild -P tests/hale_tests.gpr
./bin/run_tests
```

## Key Features

### Type Safety
- Dimensional types prevent unit mixing at compile time
- `Distance_Km`, `Velocity_Km_S`, `Angle_Radians`, etc.
- Strong typing for gravitational parameters and orbital elements

### Numerical Precision
- IEEE 754 double precision (64-bit)
- Solver tolerance: 1e-12
- Newton-Raphson and universal variable formulations

### Complete Orbital Mechanics
- **Two-Body**: Vis-viva, energy, angular momentum, orbit classification
- **Elements**: State vector ↔ orbital elements, anomaly conversions
- **Kepler**: Elliptic, hyperbolic, and universal solvers
- **Lambert**: Transfer orbit determination
- **Maneuvers**: Hohmann, bi-elliptic, plane change, phasing

## Example Usage

```ada
with Hale_Orbital.Types;     use Hale_Orbital.Types;
with Hale_Orbital.Constants; use Hale_Orbital.Constants;
with Hale_Orbital.Maneuvers; use Hale_Orbital.Maneuvers;

procedure Example is
   R_LEO : constant Distance_Km := 6678.0;  -- 300 km altitude
   R_GEO : constant Distance_Km := 42164.0;

   Result : Hohmann_Result;
begin
   Result := Hohmann_Transfer (R_LEO, R_GEO, Mu_Earth);

   -- Result.Delta_V1 ~ 2.4 km/s (first burn)
   -- Result.Delta_V2 ~ 1.5 km/s (second burn)
   -- Result.Transfer_Time ~ 5.25 hours
end Example;
```

## Remaining Work

- [ ] Interplanetary trajectories (patched conics)
- [ ] Three-body dynamics (CR3BP)
- [ ] Gravity assist calculations
- [ ] Extended test coverage
- [ ] Performance optimization

## References

- Hale, F.J. (1994). *Introduction to Space Flight*. Prentice Hall.
- Ada Reference Manual (Ada 2012)
- Vallado, D.A. (2013). *Fundamentals of Astrodynamics and Applications*. 4th ed.
