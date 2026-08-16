# Spec 00: Three-Body Extension Overview

## Purpose

This extension adds Circular Restricted Three-Body Problem (CR3BP) capabilities
to the HALE Orbital Mechanics library, enabling analysis of:
- Lagrange point orbits (L1, L2 halo orbits)
- Low-energy interplanetary transfers
- Gravity-assisted trajectory design
- Multi-body mission planning

## The Three-Body Problem

### Two-Body vs Three-Body

| Aspect | Two-Body (HALE main) | Three-Body (this extension) |
|--------|---------------------|----------------------------|
| Bodies | 2 (planet + spacecraft) | 3 (Sun + planet + spacecraft) |
| Solutions | Analytical (Kepler) | Numerical (integration) |
| Orbits | Conic sections | Complex, often chaotic |
| Conservation | Energy, angular momentum | Jacobi constant |
| Key equation | Vis-viva | Equations of motion in rotating frame |

### Circular Restricted Three-Body Problem (CR3BP)

Assumptions:
1. Two massive bodies (primaries) orbit their barycenter in circles
2. Third body (spacecraft) has negligible mass
3. Motion analyzed in rotating reference frame

Key parameter: **Mass ratio μ = m₂/(m₁ + m₂)**

## Module Structure

```
threebody/
├── constants.py    # Mass ratios, system parameters
├── systems.py      # Pre-defined systems (Sun-Earth, Earth-Moon)
├── cr3bp.py        # Equations of motion, Jacobi constant
├── lagrange.py     # L1-L5 calculation and stability
├── integrators.py  # RK4, RK45, propagation
├── periodic.py     # Halo, Lyapunov orbit finding
└── stability.py    # Monodromy matrix, manifolds
```

## Key Concepts

### 1. Rotating Reference Frame
- Origin at barycenter
- X-axis points from m₁ to m₂
- Frame rotates with angular velocity ω = 1 (normalized)

### 2. Lagrange Points
Five equilibrium points where spacecraft can remain stationary:
- **L1, L2, L3**: Collinear (unstable)
- **L4, L5**: Triangular (stable for μ < 0.0385)

### 3. Jacobi Constant
The only integral of motion in CR3BP:
```
C = 2Ω - v²
```
Determines accessible regions (zero-velocity surfaces).

### 4. Periodic Orbits
- **Lyapunov**: Planar orbits around L1, L2, L3
- **Halo**: 3D orbits around L1, L2
- **Lissajous**: Quasi-periodic 3D orbits

### 5. Invariant Manifolds
Stable/unstable manifolds of periodic orbits enable:
- Low-energy transfers
- Interplanetary superhighway
- Ballistic capture trajectories

## Real-World Applications

| Mission | System | Orbit Type |
|---------|--------|------------|
| JWST | Sun-Earth | L2 Halo |
| SOHO | Sun-Earth | L1 Halo |
| Lunar Gateway | Earth-Moon | L2 NRHO |
| ARTEMIS | Earth-Moon | L1/L2 Lyapunov |

## Dependencies

- numpy: Array operations
- scipy: Integration, optimization
- matplotlib: Visualization (optional)

## Validation Approach

1. **Lagrange Points**: Match JPL reference values
2. **Jacobi Conservation**: < 1e-10 deviation over 100 periods
3. **Periodic Orbits**: Close within 1 km after one period
4. **Mission Data**: Match JWST, Gateway parameters

## References

1. Szebehely, V. "Theory of Orbits" (1967)
2. Koon, W.S. et al. "Dynamical Systems, the Three-Body Problem and Space Mission Design" (2011)
3. Parker, J.S. & Anderson, R.L. "Low-Energy Lunar Trajectory Design" (2014)
