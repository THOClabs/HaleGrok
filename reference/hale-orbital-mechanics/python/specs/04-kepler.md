# Spec 04: Kepler's Equation

Reference: Hale Chapter 4, pp. 93-105

## The Problem

Given mean anomaly M and eccentricity e, find eccentric anomaly E.

**Kepler's Equation (Eq. 4.10):**
```
M = E - e·sin(E)
```

This transcendental equation cannot be solved analytically; must use iteration.

## Newton-Raphson Method (Hale p. 98)

**Iteration formula:**
```
E_{n+1} = E_n - f(E_n)/f'(E_n)
        = E_n - (E_n - e·sin(E_n) - M)/(1 - e·cos(E_n))
```

**Initial guess:**
```
E_0 = M                      (for e < 0.8)
E_0 = M + e·sin(M)           (for e < 0.9)
E_0 = π                      (for e > 0.9 and M near π)
```

**Convergence criterion:**
```
|E_{n+1} - E_n| < tolerance
```

Typically tolerance = 1e-12 for double precision.

## Hyperbolic Orbits (e > 1)

**Hyperbolic Kepler's Equation:**
```
M = e·sinh(H) - H
```

Where H is the hyperbolic anomaly.

**Newton-Raphson:**
```
H_{n+1} = H_n - (e·sinh(H_n) - H_n - M)/(e·cosh(H_n) - 1)
```

**Initial guess:**
```
H_0 = M                      (for M < π)
H_0 = sign(M)·ln(2|M|/e + 1.8)  (for |M| > π)
```

## Parabolic Orbits (e = 1)

**Barker's Equation:**
```
M = B + B³/3
```

Where B is the parabolic anomaly (related to true anomaly).

**Analytical solution (cubic formula):**
```
W = 3M/2
B = (W + √(W² + 1))^(1/3) - (W + √(W² + 1))^(-1/3)
```

## Universal Variable Formulation

For any orbit type (elliptic, parabolic, hyperbolic):

### Stumpff Functions (Eq. 4.35-4.36)

```
c(z) = (1 - cos(√z))/z                    for z > 0
c(z) = (cosh(√(-z)) - 1)/(-z)            for z < 0
c(0) = 1/2

s(z) = (√z - sin(√z))/(√z)³              for z > 0
s(z) = (sinh(√(-z)) - √(-z))/(√(-z))³    for z < 0
s(0) = 1/6
```

Series expansions for |z| < 1:
```
c(z) = 1/2! - z/4! + z²/6! - z³/8! + ...
s(z) = 1/3! - z/5! + z²/7! - z³/9! + ...
```

### Universal Kepler Equation

```
√μ·Δt = r_0·v_r0·χ²·c(α·χ²)/√μ + (1 - α·r_0)·χ³·s(α·χ²) + r_0·χ
```

Where:
- χ = universal anomaly
- α = 1/a (reciprocal semi-major axis)
- Δt = time of flight

### f and g Functions (Eq. 4.38-4.41)

The state at time t in terms of initial state:
```
r⃗ = f·r⃗_0 + g·v⃗_0
v⃗ = ḟ·r⃗_0 + ġ·v⃗_0
```

Where:
```
f = 1 - χ²·c(α·χ²)/r_0
g = Δt - χ³·s(α·χ²)/√μ
ḟ = √μ·χ·(α·χ²·s(α·χ²) - 1)/(r·r_0)
ġ = 1 - χ²·c(α·χ²)/r
```

## Time of Flight

### Elliptic Orbit
```
Δt = (a³/μ)^(1/2) · (ΔE - e·(sin(E_2) - sin(E_1)))
```

or using mean anomaly:
```
Δt = (M_2 - M_1)/n
```

### Hyperbolic Orbit
```
Δt = ((-a)³/μ)^(1/2) · (e·(sinh(H_2) - sinh(H_1)) - ΔH)
```

## Hale Worked Examples

### Example 4.3 (p. 99)
Given: e = 0.4, M = 30° = 0.5236 rad
Find: E using Newton-Raphson

Solution iterations:
```
E_0 = 0.5236
E_1 = 0.6508
E_2 = 0.6541
E_3 = 0.6541 (converged)
```

### Example 4.4 (p. 102)
Given: LEO satellite, a = 6678 km, e = 0.0, t_0 = 0, t = 1000 s
Find: Position at time t

### Example 4.5 (p. 104)
Given: Orbit with a = 8000 km, e = 0.2
Find: Time of flight from ν = 0° to ν = 90°

## Implementation Functions

```python
def solve_kepler_elliptic(M: float, e: float, tol: float = 1e-12) -> float:
    """
    Solve Kepler's equation for elliptic orbits.
    
    Parameters
    ----------
    M : float
        Mean anomaly [rad]
    e : float
        Eccentricity (0 ≤ e < 1)
    tol : float
        Convergence tolerance
    
    Returns
    -------
    float
        Eccentric anomaly E [rad]
    """

def solve_kepler_hyperbolic(M: float, e: float, tol: float = 1e-12) -> float:
    """
    Solve hyperbolic Kepler's equation.
    
    Parameters
    ----------
    M : float
        Mean anomaly [rad]
    e : float
        Eccentricity (e > 1)
    tol : float
        Convergence tolerance
    
    Returns
    -------
    float
        Hyperbolic anomaly H [rad]
    """

def solve_kepler_parabolic(M: float) -> float:
    """
    Solve Barker's equation for parabolic orbits.
    
    Parameters
    ----------
    M : float
        Mean anomaly [rad]
    
    Returns
    -------
    float
        Parabolic anomaly B [rad]
    """

def stumpff_c(z: float) -> float:
    """Stumpff function c(z). Hale Eq. 4.35."""

def stumpff_s(z: float) -> float:
    """Stumpff function s(z). Hale Eq. 4.36."""

def universal_kepler(dt: float, r0: float, vr0: float, a: float, mu: float) -> float:
    """
    Solve universal Kepler equation for χ.
    
    Parameters
    ----------
    dt : float
        Time of flight [s]
    r0 : float
        Initial radius [km]
    vr0 : float
        Initial radial velocity [km/s]
    a : float
        Semi-major axis [km]
    mu : float
        Gravitational parameter [km³/s²]
    
    Returns
    -------
    float
        Universal anomaly χ
    """

def f_and_g(chi: float, r0: float, a: float, mu: float) -> tuple:
    """
    Calculate f, g, f_dot, g_dot coefficients.
    
    Returns
    -------
    tuple
        (f, g, f_dot, g_dot)
    """

def propagate_kepler(r0: np.ndarray, v0: np.ndarray, dt: float, mu: float) -> tuple:
    """
    Propagate state using universal variable method.
    
    Returns
    -------
    tuple
        (r, v) at time t0 + dt
    """
```

## Convergence Considerations

| Eccentricity | Iterations (typical) | Notes |
|--------------|---------------------|-------|
| e < 0.3 | 3-4 | Fast convergence |
| 0.3 < e < 0.8 | 4-6 | Normal convergence |
| 0.8 < e < 0.95 | 6-10 | Slower, need good initial guess |
| e > 0.95 | 10-20 | Use better algorithms |
| e = 1 | 1 (analytical) | Barker's equation |
| e > 1 | 5-10 | Hyperbolic, sinh/cosh |

**Maximum iterations:** 50 (raise error if not converged)
