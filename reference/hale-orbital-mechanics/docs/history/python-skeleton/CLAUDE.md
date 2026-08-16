# CLAUDE.md - Implementation Guide

This document provides guidance for AI coding assistants working on the HALE Orbital Mechanics project.

## Project Context

This is a Python implementation of classical orbital mechanics based on Francis J. Hale's textbook. The goal is 100% traceability: every function maps to a specific equation in the textbook.

## Critical Design Decisions (Do Not Change)

1. **Units:** All distances in km, times in seconds, angles in radians internally
2. **Coordinate System:** Earth-centered inertial (ECI) J2000 frame
3. **Precision:** Float64, tolerance 1e-12 for iterative solvers
4. **Dependencies:** numpy, scipy only (no astropy, poliastro, etc.)
5. **Testing:** Every function tested against Hale examples

## Code Style

### Naming Conventions

```python
# Functions: lowercase_with_underscores
def vis_viva(r, a, mu):
    pass

# Constants: UPPERCASE_WITH_UNDERSCORES  
MU_EARTH = 398600.4418  # km³/s²

# Classes: PascalCase
class OrbitalElements:
    pass

# Private functions: _leading_underscore
def _solve_kepler_iteration(M, e, E0):
    pass
```

### Docstrings

Every public function MUST have a docstring with:
1. Brief description
2. Hale reference (chapter, equation, page)
3. Parameters with units
4. Returns with units
5. Example if non-trivial

```python
def vis_viva(r: float, a: float, mu: float) -> float:
    """
    Calculate velocity using vis-viva equation.
    
    Reference: Hale Eq. 2.20, p. 45
    
    Parameters
    ----------
    r : float
        Radius (distance from central body) [km]
    a : float
        Semi-major axis [km]
    mu : float
        Gravitational parameter [km³/s²]
    
    Returns
    -------
    float
        Velocity magnitude [km/s]
    
    Example
    -------
    >>> vis_viva(6678, 6678, 398600.4418)  # Circular LEO
    7.725...
    """
    return np.sqrt(mu * (2/r - 1/a))
```

### Type Hints

Use type hints for all functions:

```python
import numpy as np
from numpy.typing import NDArray

def rv_to_elements(
    r_vec: NDArray[np.float64], 
    v_vec: NDArray[np.float64], 
    mu: float
) -> 'OrbitalElements':
    ...
```

## Common Pitfalls

### 1. Angle Wrapping

Always normalize angles to [0, 2π) or [-π, π):

```python
def normalize_angle(angle: float) -> float:
    """Normalize angle to [0, 2π)."""
    return angle % (2 * np.pi)

def normalize_angle_symmetric(angle: float) -> float:
    """Normalize angle to [-π, π)."""
    return (angle + np.pi) % (2 * np.pi) - np.pi
```

### 2. Quadrant Ambiguity

Use `np.arctan2(y, x)` instead of `np.arctan(y/x)`:

```python
# WRONG - loses quadrant information
theta = np.arctan(y / x)

# CORRECT - preserves quadrant
theta = np.arctan2(y, x)
```

### 3. Singularities

Handle degenerate cases:
- Circular orbits (e = 0): argument of periapsis undefined
- Equatorial orbits (i = 0): RAAN undefined
- Radial orbits: angular momentum = 0

```python
def eccentricity_vector(r_vec, v_vec, mu):
    h_vec = np.cross(r_vec, v_vec)
    h_mag = np.linalg.norm(h_vec)
    
    if h_mag < 1e-10:
        raise ValueError("Radial orbit - eccentricity vector undefined")
    
    # Continue with calculation...
```

### 4. Kepler's Equation Convergence

For high eccentricity (e > 0.9), use better initial guess:

```python
def initial_guess_kepler(M: float, e: float) -> float:
    """Better initial guess for Kepler's equation."""
    if e < 0.8:
        return M  # Simple guess works for low e
    else:
        # Use series expansion for high e
        return M + e * np.sin(M) + 0.5 * e**2 * np.sin(2*M)
```

### 5. Hyperbolic vs Elliptic

Check orbit type before applying equations:

```python
def solve_kepler(M: float, e: float) -> float:
    """Solve Kepler's equation for eccentric anomaly."""
    if e < 0:
        raise ValueError("Eccentricity must be non-negative")
    elif e < 1:
        return _solve_kepler_elliptic(M, e)
    elif e == 1:
        return _solve_kepler_parabolic(M)
    else:
        return _solve_kepler_hyperbolic(M, e)
```

## Test Patterns

### Structure

```python
import pytest
import numpy as np
from hale.twobody import vis_viva, period

class TestVisViva:
    """Tests for vis-viva equation."""
    
    def test_circular_orbit(self):
        """Circular orbit: v = sqrt(mu/r)."""
        r = 6678  # km (300 km altitude)
        a = r  # circular
        mu = 398600.4418
        
        v = vis_viva(r, a, mu)
        v_expected = np.sqrt(mu / r)
        
        assert v == pytest.approx(v_expected, rel=1e-10)
    
    def test_hale_example_2_1(self):
        """Validate against Hale Example 2.1, p. 47."""
        # Given values from textbook
        r = 8000  # km
        v = 7.5  # km/s
        mu = 398600.4418
        
        # Calculate semi-major axis
        a = 1 / (2/r - v**2/mu)
        
        # Verify vis-viva
        v_calc = vis_viva(r, a, mu)
        
        assert v_calc == pytest.approx(v, rel=0.001)  # 0.1% tolerance
```

### Fixtures

```python
# conftest.py
import pytest
import numpy as np

@pytest.fixture
def earth_mu():
    """Earth gravitational parameter."""
    return 398600.4418

@pytest.fixture
def leo_circular():
    """Circular LEO at 300 km altitude."""
    return {
        'r': 6678,  # km
        'v': 7.7258,  # km/s
        'period': 5431,  # seconds
    }

@pytest.fixture
def geo():
    """Geostationary orbit."""
    return {
        'r': 42164,  # km
        'a': 42164,  # km
        'v': 3.0746,  # km/s
        'period': 86164,  # seconds (sidereal day)
    }
```

### Tolerance Guidelines

| Quantity | Relative Tolerance | Absolute Tolerance |
|----------|-------------------|-------------------|
| Position | 1e-6 | 1 km |
| Velocity | 1e-6 | 0.001 km/s |
| Time | 1e-6 | 1 second |
| Angles | 1e-6 | 0.001° |
| Δv | 1e-4 | 0.01 km/s |
| Energy | 1e-6 | - |

## File Organization

```
src/hale/
├── __init__.py      # Public API exports
├── constants.py     # Physical constants
├── twobody.py       # Chapter 2: Two-body problem
├── elements.py      # Chapters 3-4: Orbital elements
├── kepler.py        # Chapter 4: Kepler's equation
├── lambert.py       # Chapter 5: Lambert problem
├── maneuvers.py     # Chapter 6: Orbital maneuvers
├── interplanetary.py # Chapters 7-8: Patched conics
├── mission.py       # Integration module
└── utils.py         # Shared utilities
```

## Git Commit Messages

Format: `Complete: [item] - Hale [reference]`

Examples:
- `Complete: Create constants.py - Hale Appendix B`
- `Complete: Implement vis_viva() - Hale Eq. 2.20`
- `Complete: Test Kepler solver - Hale Example 4.4`

## Performance Considerations

For Lambert solver and iterative methods:
- Maximum iterations: 50
- Convergence tolerance: 1e-12
- Raise `ConvergenceError` if not converged

```python
class ConvergenceError(Exception):
    """Raised when iterative solver fails to converge."""
    pass

def solve_kepler(M: float, e: float, tol: float = 1e-12, max_iter: int = 50) -> float:
    E = initial_guess_kepler(M, e)
    
    for i in range(max_iter):
        E_new = E - (E - e * np.sin(E) - M) / (1 - e * np.cos(E))
        if abs(E_new - E) < tol:
            return E_new
        E = E_new
    
    raise ConvergenceError(f"Kepler solver failed after {max_iter} iterations")
```

## References

When implementing, cross-check against:
1. **Primary:** Hale (1994) - all equation numbers reference this
2. **Secondary:** Vallado (2013) - for numerical algorithms
3. **Validation:** JPL Horizons - for ephemeris data

## Traceability Matrix

Every function should be traceable:

| Function | Hale Reference | Test Case |
|----------|---------------|-----------|
| `vis_viva()` | Eq. 2.20, p. 45 | `test_hale_example_2_1` |
| `period()` | Eq. 2.35, p. 52 | `test_geo_period` |
| `solve_kepler()` | Eq. 4.10, p. 98 | `test_hale_example_4_4` |
| ... | ... | ... |

Update this matrix as you implement functions.
