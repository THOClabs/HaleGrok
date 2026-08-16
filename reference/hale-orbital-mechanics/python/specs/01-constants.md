# Spec 01: Physical Constants

Reference: Hale Appendix B, pp. 345-348

## Universal Constants

| Constant | Symbol | Value | Units | Source |
|----------|--------|-------|-------|--------|
| Gravitational constant | G | 6.67430 × 10⁻²⁰ | km³/(kg·s²) | CODATA 2018 |
| Speed of light | c | 299792.458 | km/s | Exact |
| Astronomical Unit | AU | 149597870.7 | km | IAU 2012 |

## Solar System Bodies

### Sun

| Property | Value | Units |
|----------|-------|-------|
| Gravitational parameter (μ) | 1.32712440018 × 10¹¹ | km³/s² |
| Radius | 696000 | km |
| Mass | 1.989 × 10³⁰ | kg |

### Earth

| Property | Value | Units |
|----------|-------|-------|
| Gravitational parameter (μ) | 398600.4418 | km³/s² |
| Equatorial radius | 6378.137 | km |
| Polar radius | 6356.752 | km |
| Mean radius | 6371.0 | km |
| Mass | 5.972 × 10²⁴ | kg |
| J₂ (oblateness) | 0.00108263 | - |
| Rotation rate | 7.2921159 × 10⁻⁵ | rad/s |
| Sidereal day | 86164.0905 | s |

### Moon

| Property | Value | Units |
|----------|-------|-------|
| Gravitational parameter (μ) | 4902.800066 | km³/s² |
| Radius | 1737.4 | km |
| Mean distance from Earth | 384400 | km |
| Orbital period | 27.321661 | days |

### Planets (Hale Table 1.1)

| Planet | μ (km³/s²) | R (km) | a (AU) | e | i (°) | T (days) |
|--------|------------|--------|--------|---|-------|----------|
| Mercury | 22032.09 | 2439.7 | 0.3871 | 0.2056 | 7.00 | 87.97 |
| Venus | 324858.63 | 6051.8 | 0.7233 | 0.0068 | 3.39 | 224.70 |
| Earth | 398600.44 | 6378.1 | 1.0000 | 0.0167 | 0.00 | 365.25 |
| Mars | 42828.37 | 3396.2 | 1.5237 | 0.0934 | 1.85 | 686.98 |
| Jupiter | 126686534 | 71492 | 5.2034 | 0.0484 | 1.30 | 4332.59 |
| Saturn | 37931187 | 60268 | 9.5371 | 0.0542 | 2.49 | 10759.2 |
| Uranus | 5793939 | 25559 | 19.191 | 0.0472 | 0.77 | 30685.4 |
| Neptune | 6836529 | 24764 | 30.069 | 0.0086 | 1.77 | 60189 |

## Sphere of Influence Radii

| Body | SOI Radius (km) | Notes |
|------|-----------------|-------|
| Earth | 924,600 | w.r.t. Sun |
| Moon | 66,200 | w.r.t. Earth |
| Mars | 577,200 | w.r.t. Sun |
| Venus | 616,300 | w.r.t. Sun |
| Jupiter | 48,200,000 | w.r.t. Sun |

Formula: r_SOI = a × (m_planet / m_sun)^(2/5)

## Standard Orbits

### Low Earth Orbit (LEO)

| Altitude | Radius | Period | Velocity |
|----------|--------|--------|----------|
| 200 km | 6578 km | 88.5 min | 7.79 km/s |
| 300 km | 6678 km | 90.5 min | 7.73 km/s |
| 400 km | 6778 km | 92.6 min | 7.67 km/s |
| ISS (~420 km) | 6798 km | 93.0 min | 7.66 km/s |

### Geostationary Orbit (GEO)

| Property | Value |
|----------|-------|
| Altitude | 35786 km |
| Radius | 42164 km |
| Period | 86164 s (23h 56m 4s) |
| Velocity | 3.075 km/s |
| Inclination | 0° |

### GPS Orbit

| Property | Value |
|----------|-------|
| Altitude | 20180 km |
| Radius | 26558 km |
| Period | 11h 58m |
| Inclination | 55° |

## Unit Conversions

```
1 AU = 149,597,870.7 km
1 day = 86,400 s
1 year = 365.25 days = 31,557,600 s
1 degree = π/180 radians
1 km/s = 3600 km/h = 2237 mph

Earth surface gravity: g₀ = 9.80665 m/s²
Standard gravitational acceleration for Isp: g₀ = 0.00980665 km/s²
```

## Implementation Notes

### Python Module Structure

```python
# constants.py

# Universal
G = 6.67430e-20  # km³/(kg·s²)
C = 299792.458   # km/s
AU = 149597870.7  # km

# Sun
MU_SUN = 1.32712440018e11  # km³/s²
R_SUN = 696000  # km

# Earth
MU_EARTH = 398600.4418  # km³/s²
R_EARTH = 6378.137  # km
J2_EARTH = 0.00108263
OMEGA_EARTH = 7.2921159e-5  # rad/s
SIDEREAL_DAY = 86164.0905  # s

# Moon
MU_MOON = 4902.800066  # km³/s²
R_MOON = 1737.4  # km
A_MOON = 384400  # km (mean distance from Earth)

# Planets dict
PLANETS = {
    'mercury': {'mu': 22032.09, 'radius': 2439.7, 'a': 0.3871 * AU, ...},
    'venus': {'mu': 324858.63, 'radius': 6051.8, 'a': 0.7233 * AU, ...},
    ...
}
```

### Precision Requirements

- Gravitational parameters: 8 significant figures minimum
- Radii: 5 significant figures
- Orbital elements: 4 significant figures
- All values should be Float64
