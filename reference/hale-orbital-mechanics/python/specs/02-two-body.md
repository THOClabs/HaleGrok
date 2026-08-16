# Spec 02: Two-Body Problem

Reference: Hale Chapter 2, pp. 23-70

## Fundamental Assumptions

1. Two bodies only (spacecraft negligible mass)
2. Point masses (or spherically symmetric)
3. No other forces (drag, solar pressure, third bodies)
4. Newtonian gravity: F = -μm/r²

## Core Equations

### Vis-Viva Equation (Eq. 2.20)

The energy equation relating velocity to position:

```
v² = μ(2/r - 1/a)
```

Where:
- v = velocity magnitude [km/s]
- μ = gravitational parameter [km³/s²]
- r = radius (distance from central body) [km]
- a = semi-major axis [km]

Special cases:
- Circular orbit (r = a): v = √(μ/r)
- Escape (a → ∞): v = √(2μ/r)

### Specific Orbital Energy (Eq. 2.16)

```
ε = v²/2 - μ/r = -μ/(2a)
```

- ε < 0: Elliptical (bound) orbit
- ε = 0: Parabolic trajectory
- ε > 0: Hyperbolic trajectory

### Specific Angular Momentum (Eq. 2.11)

```
h⃗ = r⃗ × v⃗
h = r·v·cos(γ)
```

Where γ is the flight path angle.

For any Keplerian orbit: h = √(μ·a·(1-e²))

### Orbital Period (Eq. 2.35)

```
T = 2π√(a³/μ)
```

### Mean Motion (Eq. 2.36)

```
n = √(μ/a³) = 2π/T
```

## Conic Section Geometry

### Orbit Equation (Eq. 2.29)

```
r = a(1-e²)/(1 + e·cos(θ))
```

Where θ is the true anomaly.

Alternative form using semi-latus rectum p:
```
p = a(1-e²) = h²/μ
r = p/(1 + e·cos(θ))
```

### Periapsis and Apoapsis (Eq. 2.30-2.31)

```
r_p = a(1-e)      # periapsis (closest approach)
r_a = a(1+e)      # apoapsis (farthest point)
```

### Eccentricity from Apsides

```
e = (r_a - r_p)/(r_a + r_p)
a = (r_a + r_p)/2
```

### Flight Path Angle (Eq. 2.46)

```
tan(γ) = e·sin(θ)/(1 + e·cos(θ))
```

At periapsis (θ=0) and apoapsis (θ=π): γ = 0

### Velocity Components (Eq. 2.44-2.45)

Radial velocity:
```
v_r = (μ/h)·e·sin(θ)
```

Transverse velocity:
```
v_θ = (μ/h)·(1 + e·cos(θ))
```

Total velocity:
```
v = √(v_r² + v_θ²)
```

## Eccentricity Vector

```
e⃗ = (v⃗ × h⃗)/μ - r̂
```

Magnitude: e = |e⃗| (eccentricity)
Direction: points toward periapsis

## Orbit Types

| Type | Eccentricity | Energy | Semi-major axis |
|------|--------------|--------|-----------------|
| Circular | e = 0 | ε < 0 | a > 0 |
| Elliptical | 0 < e < 1 | ε < 0 | a > 0 |
| Parabolic | e = 1 | ε = 0 | a = ∞ |
| Hyperbolic | e > 1 | ε > 0 | a < 0 |

## Escape Velocity

```
v_esc = √(2μ/r)
```

## Circular Velocity

```
v_circ = √(μ/r)
```

Ratio: v_esc/v_circ = √2 ≈ 1.414

## Hale Worked Examples

### Example 2.1 (p. 47)
Given: Earth satellite at r = 8000 km, v = 7.5 km/s
Find: Semi-major axis, eccentricity, periapsis, apoapsis

### Example 2.2 (p. 51)  
Given: Satellite at r = 10000 km, v = 8.0 km/s
Find: Orbit type, escape velocity

### Example 2.3 (p. 58)
Given: Orbit with a = 10000 km, e = 0.3
Find: Flight path angle at θ = 45°

## Implementation Functions

```python
def vis_viva(r: float, a: float, mu: float) -> float:
    """Hale Eq. 2.20"""

def specific_energy(r: float, v: float, mu: float) -> float:
    """Hale Eq. 2.16"""

def specific_angular_momentum(r_vec: np.ndarray, v_vec: np.ndarray) -> np.ndarray:
    """Hale Eq. 2.11"""

def period(a: float, mu: float) -> float:
    """Hale Eq. 2.35"""

def mean_motion(a: float, mu: float) -> float:
    """Hale Eq. 2.36"""

def semimajor_axis_from_energy(energy: float, mu: float) -> float:
    """Inverse of Eq. 2.16"""

def eccentricity_from_apsides(r_p: float, r_a: float) -> float:
    """From Eq. 2.30-2.31"""

def periapsis(a: float, e: float) -> float:
    """Hale Eq. 2.30"""

def apoapsis(a: float, e: float) -> float:
    """Hale Eq. 2.31"""

def radius_at_true_anomaly(a: float, e: float, theta: float) -> float:
    """Hale Eq. 2.29"""

def flight_path_angle(e: float, theta: float) -> float:
    """Hale Eq. 2.46"""

def escape_velocity(r: float, mu: float) -> float:
    """v_esc = sqrt(2μ/r)"""

def circular_velocity(r: float, mu: float) -> float:
    """v_circ = sqrt(μ/r)"""

def orbit_type(e: float) -> str:
    """Returns 'circular', 'elliptical', 'parabolic', or 'hyperbolic'"""

def is_bound(energy: float) -> bool:
    """Returns True if orbit is bound (ε < 0)"""
```
