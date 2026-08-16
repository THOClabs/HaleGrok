# Three-Body Problem Extension

An extension to the HALE Orbital Mechanics library that adds three-body dynamics capabilities.

## Status: PLANNING

This extension is currently in the planning phase. See [PLAN.md](PLAN.md) for the detailed project plan.

## What is the Three-Body Problem?

The **two-body problem** (main HALE project) considers only two gravitational bodies and has elegant analytical solutions. The **three-body problem** considers three gravitational bodies and generally requires numerical methods.

### Why it Matters

- **JWST** orbits the Sun-Earth L2 Lagrange point
- **Lunar Gateway** will orbit in Earth-Moon L2 halo orbit
- **Low-energy transfers** to the Moon use three-body dynamics
- **Interplanetary superhighway** exploits three-body manifolds

## Key Capabilities (Planned)

1. **Circular Restricted Three-Body Problem (CR3BP)**
2. **Lagrange Point Calculations** (L1-L5)
3. **Periodic Orbits** (Halo, Lyapunov, Lissajous)
4. **Numerical Integration** (RK4, RK45, Symplectic)
5. **Stability Analysis & Invariant Manifolds**
6. **Low-Energy Trajectory Design**

## Isolation

This folder is intentionally isolated from the main HALE project to:
- Allow independent development
- Prevent mixing two-body and three-body code prematurely
- Enable clean integration later if desired

## Quick Links

- [Detailed Plan](PLAN.md) - Full project specification
- [Implementation Plan](IMPLEMENTATION_PLAN.md) - Task checklist (coming soon)

## References

- Szebehely, V. "Theory of Orbits: The Restricted Problem of Three Bodies"
- Koon, W.S. et al. "Dynamical Systems, the Three-Body Problem and Space Mission Design"
