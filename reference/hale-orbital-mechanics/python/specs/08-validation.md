# Spec 08: Validation Suite

Reference: Hale textbook examples + real mission data

## Validation Philosophy

Three levels of validation:
1. **Hale Examples:** Reproduce textbook worked examples
2. **Cross-Reference:** Match other authoritative sources (Vallado, Curtis)
3. **Real Missions:** Validate against actual flight data

## Hale Textbook Examples

### Chapter 2: Two-Body Problem

| Example | Given | Find | Expected |
|---------|-------|------|----------|
| 2.1 | r=8000km, v=7.5km/s | a, e, r_p, r_a | a=9696km, e=0.175 |
| 2.2 | r=10000km, v=8.0km/s | orbit type | Hyperbolic |
| 2.3 | a=10000km, e=0.3, θ=45° | γ (flight path angle) | 13.4° |

### Chapter 4: Orbital Elements

| Example | Given | Find | Expected |
|---------|-------|------|----------|
| 4.1 | r⃗, v⃗ (see spec) | a, e, i, Ω, ω, ν | Values in text |
| 4.2 | Elements (see spec) | r⃗, v⃗ | Vectors in text |
| 4.3 | e=0.4, M=30° | E | 37.48° |
| 4.4 | a=6678km, e=0, t=1000s | position | ν = 86.8° |
| 4.5 | a=8000km, e=0.2 | TOF (0° to 90°) | 1345.3s |

### Chapter 5: Lambert Problem

| Example | Given | Find | Expected |
|---------|-------|------|----------|
| 5.1 | r1, r2, Δt | v1, v2 | Transfer velocities |
| 5.2 | Multi-rev case | v1, v2 | Multiple solutions |

### Chapter 6: Maneuvers

| Example | Given | Find | Expected |
|---------|-------|------|----------|
| 6.1 | LEO to GEO | Δv_total | 3.935 km/s |
| 6.2 | GEO to LEO | Δv_total | 3.935 km/s |
| 6.3 | Bi-elliptic | Δv_total, crossover | ~11.94 ratio |
| 6.4 | Plane change | Δv | Function of v, Δi |
| 6.5 | Rendezvous | Wait time | Function of phase |

### Chapter 7: Interplanetary

| Example | Given | Find | Expected |
|---------|-------|------|----------|
| 7.1 | Earth-Mars Hohmann | C3, Δv | ~8.6 km²/s², ~3.6 km/s |
| 7.2 | Jupiter flyby | Turning angle | Function of r_p |
| 7.3 | Launch window | Phase angle | ~44° |

## Real Mission Validation

### Apollo 11 (July 1969)

| Phase | Parameter | Expected | Tolerance |
|-------|-----------|----------|-----------|
| TLI burn | Δv | 3.05 km/s | ±0.05 |
| Transit time | Δt | 3 days | ±0.5 days |
| LOI burn | Δv | 0.89 km/s | ±0.05 |
| Parking orbit | h | 100 km | ±10 km |

### Mars Missions (Typical Hohmann)

| Parameter | Expected | Source |
|-----------|----------|--------|
| Transfer time | 259 days | Orbital mechanics |
| C3 (departure) | 8-16 km²/s² | JPL |
| V_infinity arrival | 2.5-3.5 km/s | JPL |

### GPS Constellation

| Parameter | Expected | Tolerance |
|-----------|----------|-----------|
| Semi-major axis | 26,559.7 km | ±1 km |
| Period | 11h 58m 2s | ±1 s |
| Inclination | 55° | ±0.1° |

### ISS Orbit

| Parameter | Expected | Tolerance |
|-----------|----------|-----------|
| Altitude | 408-420 km | ±10 km |
| Period | 92.68 min | ±0.1 min |
| Inclination | 51.6° | ±0.1° |

## Cross-Reference Sources

### Vallado (4th Edition)

| Algorithm | Vallado Page | Hale Equiv |
|-----------|--------------|------------|
| RV to COE | 113-117 | Ch. 4 |
| COE to RV | 118-119 | Ch. 4 |
| Kepler Universal | 93-96 | Ch. 4 |
| Lambert Universal | 467-473 | Ch. 5 |
| Hohmann | 326 | Ch. 6 |

### JPL Horizons

Use for planetary ephemerides validation:
- Earth orbital elements
- Mars orbital elements
- Planetary positions at specific epochs

## Error Tolerances

| Quantity | Relative | Absolute | Notes |
|----------|----------|----------|-------|
| Position | 1e-6 | 1 km | Earth orbits |
| Velocity | 1e-6 | 1 m/s | |
| Angles | 1e-6 | 0.001° | |
| Time | 1e-6 | 1 s | Periods, TOF |
| Δv | 1e-4 | 10 m/s | Maneuvers |
| Energy | 1e-8 | - | Conservation |
| Ang. Mom. | 1e-8 | - | Conservation |

## Test Categories

### Unit Tests (per function)
- Input validation
- Edge cases (e=0, e=1, i=0)
- Known values

### Integration Tests
- RV → Elements → RV roundtrip
- Propagate forward then backward
- Maneuver sequences

### Validation Tests
- Hale examples (must match exactly)
- Real mission data (within tolerance)
- Conservation laws

## Test Fixtures

```python
# conftest.py

import pytest
import numpy as np

@pytest.fixture
def hale_example_4_1():
    """Hale Example 4.1 state vector."""
    return {
        'r': np.array([6524.834, 6862.875, 6448.296]),  # km
        'v': np.array([4.901327, 5.533756, -1.976341]),  # km/s
        'mu': 398600.4418,
        'expected': {
            'a': 36127.343,  # km
            'e': 0.83285,
            'i': np.radians(87.87),
            'raan': np.radians(227.89),
            'omega': np.radians(53.38),
            'nu': np.radians(92.335),
        }
    }

@pytest.fixture
def apollo_11_tli():
    """Apollo 11 TLI parameters."""
    return {
        'r_parking': 6563,  # km (185 km altitude)
        'v_departure': 10.84,  # km/s
        'dv_tli': 3.05,  # km/s
        'mu_earth': 398600.4418,
    }

@pytest.fixture
def hohmann_leo_to_geo():
    """Standard LEO to GEO Hohmann transfer."""
    return {
        'r1': 6678,  # km (300 km altitude)
        'r2': 42164,  # km (GEO)
        'mu': 398600.4418,
        'dv1': 2.426,  # km/s
        'dv2': 1.467,  # km/s
        'dv_total': 3.893,  # km/s
        'tof': 19077,  # s (~5.3 hours)
    }
```

## Expected Test Counts

| Module | Unit Tests | Integration | Validation | Total |
|--------|------------|-------------|------------|-------|
| constants | 15 | 0 | 5 | 20 |
| twobody | 20 | 5 | 5 | 30 |
| elements | 20 | 10 | 5 | 35 |
| kepler | 15 | 5 | 5 | 25 |
| lambert | 10 | 5 | 5 | 20 |
| maneuvers | 15 | 5 | 5 | 25 |
| interplanetary | 10 | 5 | 5 | 20 |
| **Total** | **105** | **35** | **35** | **175** |
