# Three-Body Problem Extension - Project Plan

**Parent Project:** HALE Orbital Mechanics
**Status:** PLANNING
**Created:** 2025-12-31

---

## Overview

This extension adds three-body dynamics to the HALE orbital mechanics library. While the main HALE project focuses on the classical two-body problem (analytical solutions), this extension tackles the more complex three-body problem which generally requires numerical methods.

### Why Three-Body?

The two-body problem assumes only two gravitational bodies exist. In reality:
- Spacecraft traveling to the Moon feel both Earth AND Moon gravity
- Satellites at Lagrange points balance between Sun and Earth gravity
- The James Webb Space Telescope orbits the Sun-Earth L2 point
- Future Lunar Gateway station will use three-body dynamics

---

## Scope

### In Scope

1. **Circular Restricted Three-Body Problem (CR3BP)**
   - Two primary masses in circular orbits around their barycenter
   - Third body (spacecraft) has negligible mass
   - Most practical for mission design

2. **Lagrange Points**
   - L1, L2, L3 (unstable collinear points)
   - L4, L5 (stable triangular points)
   - Position and stability calculations

3. **Periodic Orbits**
   - Halo orbits (around L1, L2)
   - Lyapunov orbits (planar)
   - Lissajous orbits (quasi-periodic)

4. **Numerical Integration**
   - Runge-Kutta methods (RK4, RK45)
   - Symplectic integrators (for long-term accuracy)
   - Adaptive step-size control

5. **Trajectory Design**
   - Low-energy transfers
   - Manifold-based trajectory design
   - Station-keeping at Lagrange points

6. **Real-World Systems**
   - Sun-Earth system
   - Earth-Moon system
   - Sun-Jupiter system (for asteroid studies)

### Out of Scope (Future Work)

- General N-body problem (N > 3)
- Full ephemeris models (actual planetary positions)
- Relativistic corrections
- Solar radiation pressure perturbations
- Monte Carlo analysis

---

## Project Structure

```
three-body-extension/
├── PLAN.md                    # This file
├── IMPLEMENTATION_PLAN.md     # Detailed task checklist
├── README.md                  # Usage documentation
│
├── specs/                     # Technical specifications
│   ├── 00-overview.md         # Project overview
│   ├── 01-cr3bp-fundamentals.md   # CR3BP theory
│   ├── 02-equations-of-motion.md  # Differential equations
│   ├── 03-lagrange-points.md      # L1-L5 calculations
│   ├── 04-numerical-integration.md # Integrator specs
│   ├── 05-periodic-orbits.md      # Halo, Lyapunov, Lissajous
│   ├── 06-stability-analysis.md   # Floquet theory, manifolds
│   ├── 07-trajectory-design.md    # Mission applications
│   └── 08-validation.md           # Test cases and validation
│
├── src/
│   └── threebody/
│       ├── __init__.py
│       ├── constants.py       # Three-body specific constants
│       ├── cr3bp.py           # Core CR3BP equations
│       ├── lagrange.py        # Lagrange point calculations
│       ├── integrators.py     # Numerical integration methods
│       ├── periodic.py        # Periodic orbit computation
│       ├── stability.py       # Stability and manifolds
│       ├── trajectories.py    # Trajectory design tools
│       └── systems.py         # Pre-defined systems (Sun-Earth, etc.)
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py            # Shared fixtures
│   ├── test_cr3bp.py
│   ├── test_lagrange.py
│   ├── test_integrators.py
│   ├── test_periodic.py
│   ├── test_stability.py
│   └── test_trajectories.py
│
├── examples/
│   ├── jwst_orbit.py          # JWST at Sun-Earth L2
│   ├── lunar_gateway.py       # Earth-Moon L2 halo orbit
│   ├── low_energy_transfer.py # Earth-Moon transfer
│   └── visualizations.py      # Plotting utilities
│
└── requirements.txt           # Additional dependencies
```

---

## Phase Breakdown

### Phase 1: Foundation (Week 1-2)
**Goal:** Set up project and implement core CR3BP equations

#### 1.1 Project Setup
- [ ] Create directory structure
- [ ] Set up `__init__.py` files
- [ ] Create `requirements.txt` (numpy, scipy, matplotlib)
- [ ] Create test fixtures in `conftest.py`

#### 1.2 Constants and Systems
- [ ] Define mass ratios for common systems:
  - Sun-Earth: μ ≈ 3.003 × 10⁻⁶
  - Earth-Moon: μ ≈ 0.01215
  - Sun-Jupiter: μ ≈ 9.537 × 10⁻⁴
- [ ] Define characteristic units (length, time, velocity)
- [ ] Create `System` class to hold parameters

#### 1.3 CR3BP Equations of Motion
- [ ] Implement rotating frame equations:
  ```
  ẍ - 2ẏ = ∂Ω/∂x
  ÿ + 2ẋ = ∂Ω/∂y
  z̈ = ∂Ω/∂z
  ```
- [ ] Implement pseudo-potential Ω(x, y, z)
- [ ] Implement Jacobi constant calculation
- [ ] Create state vector derivative function for integrators

**Validation:** Unit tests for equations, energy conservation

---

### Phase 2: Lagrange Points (Week 2-3)
**Goal:** Calculate and analyze all five Lagrange points

#### 2.1 Collinear Points (L1, L2, L3)
- [ ] Implement quintic equation solver for L1, L2, L3 positions
- [ ] Use Newton-Raphson for high precision
- [ ] Validate against known values (Sun-Earth L2 ≈ 1.5 million km from Earth)

#### 2.2 Triangular Points (L4, L5)
- [ ] Calculate L4/L5 positions (analytical solution exists)
- [ ] Verify equilateral triangle geometry

#### 2.3 Stability Analysis
- [ ] Linearize equations around each Lagrange point
- [ ] Calculate eigenvalues of linearized system
- [ ] Classify stability (L1, L2, L3: unstable saddle; L4, L5: stable if μ < 0.0385)

**Validation:**
- Sun-Earth L1: ~1.5 million km sunward
- Sun-Earth L2: ~1.5 million km anti-sunward
- L4/L5: 60° ahead/behind Earth in orbit

---

### Phase 3: Numerical Integration (Week 3-4)
**Goal:** Implement robust numerical integrators

#### 3.1 Basic Integrators
- [ ] Runge-Kutta 4th order (RK4)
- [ ] Runge-Kutta-Fehlberg (RK45) with adaptive step
- [ ] Wrapper for scipy.integrate.solve_ivp

#### 3.2 Symplectic Integrators
- [ ] Leapfrog/Störmer-Verlet method
- [ ] 4th order symplectic integrator
- [ ] Important for long-term orbital stability

#### 3.3 Integration Utilities
- [ ] State transition matrix propagation
- [ ] Event detection (plane crossings, periapsis, etc.)
- [ ] Dense output interpolation

**Validation:**
- Jacobi constant conservation over long integrations
- Known periodic orbits close after one period
- Compare RK45 vs symplectic for 100+ orbital periods

---

### Phase 4: Periodic Orbits (Week 4-6)
**Goal:** Compute periodic orbits around Lagrange points

#### 4.1 Lyapunov Orbits
- [ ] Planar periodic orbits around L1, L2, L3
- [ ] Differential correction algorithm
- [ ] Family continuation (vary Jacobi constant)

#### 4.2 Halo Orbits
- [ ] 3D periodic orbits around L1, L2
- [ ] Northern and Southern family
- [ ] Richardson 3rd-order analytical approximation for initial guess

#### 4.3 Lissajous Orbits
- [ ] Quasi-periodic orbits
- [ ] Amplitude control
- [ ] JWST-style mission orbits

#### 4.4 Orbit Families
- [ ] Natural parameter continuation
- [ ] Bifurcation detection
- [ ] Period vs amplitude relationships

**Validation:**
- JWST orbit parameters
- SOHO orbit at Sun-Earth L1
- Artemis mission Earth-Moon L2 halo

---

### Phase 5: Stability and Manifolds (Week 6-8)
**Goal:** Analyze orbit stability and compute invariant manifolds

#### 5.1 Monodromy Matrix
- [ ] Compute state transition matrix over one period
- [ ] Extract eigenvalues (Floquet multipliers)
- [ ] Classify orbit stability

#### 5.2 Invariant Manifolds
- [ ] Stable manifold computation (approaching orbit)
- [ ] Unstable manifold computation (departing orbit)
- [ ] Globalization via integration

#### 5.3 Manifold Applications
- [ ] Low-energy transfer design
- [ ] Heteroclinic/homoclinic connections
- [ ] Transit orbits

**Validation:**
- Manifold tubes connect L1 and L2 regions
- Low-energy lunar transfer trajectories

---

### Phase 6: Trajectory Design (Week 8-10)
**Goal:** Practical mission design tools

#### 6.1 Low-Energy Transfers
- [ ] Earth-Moon transfer via L1
- [ ] Weak stability boundary captures
- [ ] Comparison with Hohmann (fuel savings)

#### 6.2 Station-Keeping
- [ ] Lissajous orbit maintenance
- [ ] Delta-v budget estimation
- [ ] JWST-style station-keeping

#### 6.3 Interplanetary Applications
- [ ] Interplanetary superhighway concepts
- [ ] Jupiter moon tours (Galilean moons)
- [ ] Sun-Earth L2 to Moon transfers

**Validation:**
- JWST station-keeping budget (~2-4 m/s/year)
- Genesis mission trajectory reconstruction
- ARTEMIS mission validation

---

### Phase 7: Visualization and Examples (Week 10-11)
**Goal:** Create useful visualizations and example scripts

#### 7.1 Plotting Utilities
- [ ] Rotating frame orbit plots
- [ ] Inertial frame animations
- [ ] 3D halo orbit visualization
- [ ] Manifold tube plotting

#### 7.2 Example Missions
- [ ] JWST orbit simulation
- [ ] Lunar Gateway halo orbit
- [ ] Low-energy Earth-Moon transfer
- [ ] L4/L5 Trojan asteroid mission

---

### Phase 8: Documentation and Integration (Week 11-12)
**Goal:** Complete documentation and integrate with main HALE project

#### 8.1 Documentation
- [ ] Complete docstrings for all functions
- [ ] README with quick start guide
- [ ] Theory reference document
- [ ] Jupyter notebook tutorials

#### 8.2 Integration Points
- [ ] Use HALE constants where applicable
- [ ] Coordinate frame transformations to/from HALE
- [ ] Patched conic handoff to three-body

---

## Key Equations Reference

### CR3BP Equations of Motion (Rotating Frame)

```
ẍ - 2ẏ = x - (1-μ)(x+μ)/r₁³ - μ(x-1+μ)/r₂³
ÿ + 2ẋ = y - (1-μ)y/r₁³ - μy/r₂³
z̈ = -(1-μ)z/r₁³ - μz/r₂³

where:
r₁ = √((x+μ)² + y² + z²)      (distance to larger primary)
r₂ = √((x-1+μ)² + y² + z²)    (distance to smaller primary)
μ = m₂/(m₁+m₂)                 (mass ratio)
```

### Jacobi Constant (Energy-like Integral)

```
C = (x² + y²) + 2(1-μ)/r₁ + 2μ/r₂ - (ẋ² + ẏ² + ż²)
```

### Lagrange Point Positions (Approximate)

For small μ:
```
L1: x ≈ 1 - (μ/3)^(1/3)
L2: x ≈ 1 + (μ/3)^(1/3)
L3: x ≈ -1 - 5μ/12
L4: (x, y) = (1/2 - μ, √3/2)
L5: (x, y) = (1/2 - μ, -√3/2)
```

---

## Dependencies

```
# requirements.txt
numpy>=1.20
scipy>=1.7
matplotlib>=3.5      # For visualization
pytest>=7.0
pytest-cov>=4.0

# Optional
numba>=0.56          # For JIT compilation of integrators
jupyter>=1.0         # For tutorial notebooks
```

---

## Validation Sources

1. **Textbooks:**
   - Szebehely, V. "Theory of Orbits: The Restricted Problem of Three Bodies"
   - Koon, W.S. et al. "Dynamical Systems, the Three-Body Problem and Space Mission Design"

2. **Real Missions:**
   - JWST (Sun-Earth L2 halo orbit)
   - SOHO (Sun-Earth L1 halo orbit)
   - ARTEMIS (Earth-Moon L1/L2)
   - Genesis (Sun-Earth L1, sample return)

3. **JPL Data:**
   - Lagrange point positions
   - Mission trajectories

---

## Success Criteria

1. **Accuracy:** Jacobi constant conserved to 1e-10 over 100 orbital periods
2. **Completeness:** All 5 Lagrange points computed for any mass ratio
3. **Periodic Orbits:** Halo orbit closes to within 1 km after one period
4. **Validation:** Match JWST orbital parameters to within 1%
5. **Performance:** Integrate 1000 orbital periods in < 10 seconds
6. **Test Coverage:** 100+ tests, 100% pass rate

---

## Estimated Effort

| Phase | Duration | Hours |
|-------|----------|-------|
| 1: Foundation | 2 weeks | 16 |
| 2: Lagrange Points | 1 week | 8 |
| 3: Numerical Integration | 1 week | 10 |
| 4: Periodic Orbits | 2 weeks | 20 |
| 5: Stability & Manifolds | 2 weeks | 16 |
| 6: Trajectory Design | 2 weeks | 16 |
| 7: Visualization | 1 week | 8 |
| 8: Documentation | 1 week | 6 |
| **Total** | **12 weeks** | **100 hours** |

---

## Notes and Open Questions

1. **Integration with HALE:** Should three-body be a subpackage of HALE or standalone?
   - Current decision: Standalone in isolated folder, can integrate later

2. **Coordinate Systems:** Need clear transformations between:
   - Rotating frame (CR3BP standard)
   - Inertial frame (for visualization)
   - Body-centered frames (for close approaches)

3. **Performance:** Consider Numba JIT compilation for integrators if speed is critical

4. **Ephemeris Option:** Future work could add option to use real ephemeris instead of circular primaries (Elliptic R3BP or full ephemeris model)

---

*This plan will be refined as we progress. Next step: Create detailed IMPLEMENTATION_PLAN.md with checkbox items.*
