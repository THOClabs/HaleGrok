# Spec 03: Orbital Elements

Reference: Hale Chapters 3-4, pp. 71-128

## Classical Orbital Elements (COEs)

Six parameters uniquely define a Keplerian orbit:

| Element | Symbol | Description | Range |
|---------|--------|-------------|-------|
| Semi-major axis | a | Orbit size | > 0 (ellipse), < 0 (hyperbola) |
| Eccentricity | e | Orbit shape | ≥ 0 |
| Inclination | i | Orbital plane tilt | [0, π] |
| RAAN | Ω | Ascending node location | [0, 2π) |
| Argument of periapsis | ω | Periapsis location | [0, 2π) |
| True anomaly | ν (or θ) | Position on orbit | [0, 2π) |

### Alternative Sixth Element

Instead of true anomaly, can use:
- **Mean anomaly (M):** Fictitious angle, uniform in time
- **Eccentric anomaly (E):** Geometric construction
- **Time of periapsis passage (t_p):** Epoch reference

## Reference Frames

### Earth-Centered Inertial (ECI) - J2000

- **Origin:** Earth center of mass
- **X-axis:** Vernal equinox direction (First Point of Aries)
- **Z-axis:** North celestial pole (perpendicular to equator)
- **Y-axis:** Completes right-handed system

### Perifocal Frame (PQW)

- **Origin:** Central body center
- **P-axis:** Toward periapsis
- **Q-axis:** In orbital plane, 90° from P in direction of motion
- **W-axis:** Normal to orbital plane (h⃗ direction)

## State Vector ↔ Elements Conversion

### From State Vector to Elements (Hale pp. 105-110)

Given: r⃗, v⃗, μ

**Step 1:** Calculate angular momentum
```
h⃗ = r⃗ × v⃗
h = |h⃗|
```

**Step 2:** Calculate node vector
```
n⃗ = k̂ × h⃗
n = |n⃗|
```
(k̂ is unit vector in Z direction)

**Step 3:** Calculate eccentricity vector
```
e⃗ = (1/μ)[(v² - μ/r)r⃗ - (r⃗·v⃗)v⃗]
e = |e⃗|
```

**Step 4:** Calculate specific energy
```
ε = v²/2 - μ/r
```

**Step 5:** Semi-major axis
```
if e ≠ 1:  a = -μ/(2ε)
if e = 1:  a = ∞ (parabola)
```

**Step 6:** Inclination
```
i = arccos(h_z / h)
```

**Step 7:** RAAN (Ω)
```
Ω = arccos(n_x / n)
if n_y < 0: Ω = 2π - Ω
```

**Step 8:** Argument of periapsis (ω)
```
ω = arccos(n⃗·e⃗ / (n·e))
if e_z < 0: ω = 2π - ω
```

**Step 9:** True anomaly (ν)
```
ν = arccos(e⃗·r⃗ / (e·r))
if r⃗·v⃗ < 0: ν = 2π - ν
```

### From Elements to State Vector (Hale pp. 110-115)

Given: a, e, i, Ω, ω, ν, μ

**Step 1:** Position in perifocal frame
```
p = a(1 - e²)
r = p / (1 + e·cos(ν))

r_pqw = r·[cos(ν), sin(ν), 0]ᵀ
```

**Step 2:** Velocity in perifocal frame
```
v_pqw = √(μ/p)·[-sin(ν), e + cos(ν), 0]ᵀ
```

**Step 3:** Rotation matrix (PQW → ECI)
```
R = R_z(-Ω) · R_x(-i) · R_z(-ω)
```

Expanded:
```
R₁₁ = cos(Ω)cos(ω) - sin(Ω)sin(ω)cos(i)
R₁₂ = -cos(Ω)sin(ω) - sin(Ω)cos(ω)cos(i)
R₁₃ = sin(Ω)sin(i)
R₂₁ = sin(Ω)cos(ω) + cos(Ω)sin(ω)cos(i)
R₂₂ = -sin(Ω)sin(ω) + cos(Ω)cos(ω)cos(i)
R₂₃ = -cos(Ω)sin(i)
R₃₁ = sin(ω)sin(i)
R₃₂ = cos(ω)sin(i)
R₃₃ = cos(i)
```

**Step 4:** Transform to ECI
```
r⃗ = R · r_pqw
v⃗ = R · v_pqw
```

## Anomaly Conversions

### True ↔ Eccentric Anomaly

True to Eccentric (Eq. 4.13):
```
tan(E/2) = √((1-e)/(1+e)) · tan(ν/2)
```

or:
```
cos(E) = (e + cos(ν)) / (1 + e·cos(ν))
sin(E) = √(1-e²)·sin(ν) / (1 + e·cos(ν))
```

Eccentric to True (Eq. 4.14):
```
tan(ν/2) = √((1+e)/(1-e)) · tan(E/2)
```

or:
```
cos(ν) = (cos(E) - e) / (1 - e·cos(E))
sin(ν) = √(1-e²)·sin(E) / (1 - e·cos(E))
```

### Eccentric ↔ Mean Anomaly

**Kepler's Equation (Eq. 4.10):**
```
M = E - e·sin(E)
```

Solving for E given M requires iteration (see Spec 04).

### Time Relationships

Mean anomaly at time t:
```
M = M₀ + n(t - t₀)
```

where n = √(μ/a³) is mean motion.

## Singularities and Special Cases

### Circular Orbit (e = 0)

- ω undefined (no periapsis)
- Use argument of latitude: u = ω + ν

### Equatorial Orbit (i = 0 or π)

- Ω undefined (no ascending node)
- Use longitude of periapsis: ϖ = Ω + ω

### Circular Equatorial (e = 0, i = 0)

- Both ω and Ω undefined
- Use true longitude: λ = Ω + ω + ν

## Hale Worked Examples

### Example 4.1 (p. 106)
Given: r⃗ = [6524.834, 6862.875, 6448.296] km
       v⃗ = [4.901327, 5.533756, -1.976341] km/s
Find: All six orbital elements

### Example 4.2 (p. 114)
Given: a = 8000 km, e = 0.2, i = 40°, Ω = 60°, ω = 30°, ν = 50°
Find: r⃗ and v⃗ in ECI

## Implementation Data Structure

```python
from dataclasses import dataclass
import numpy as np

@dataclass
class OrbitalElements:
    """Classical orbital elements."""
    a: float        # Semi-major axis [km]
    e: float        # Eccentricity [-]
    i: float        # Inclination [rad]
    raan: float     # Right ascension of ascending node [rad]
    omega: float    # Argument of periapsis [rad]
    nu: float       # True anomaly [rad]
    
    @property
    def period(self) -> float:
        """Orbital period [s]."""
        return 2 * np.pi * np.sqrt(self.a**3 / MU_EARTH)
    
    @property
    def mean_motion(self) -> float:
        """Mean motion [rad/s]."""
        return np.sqrt(MU_EARTH / self.a**3)

def rv_to_elements(r: np.ndarray, v: np.ndarray, mu: float) -> OrbitalElements:
    """Convert state vector to orbital elements."""
    ...

def elements_to_rv(elem: OrbitalElements, mu: float) -> tuple[np.ndarray, np.ndarray]:
    """Convert orbital elements to state vector."""
    ...
```
