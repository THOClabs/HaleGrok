"""
Shared test fixtures for HALE Orbital Mechanics.

Fixtures provide common test data including:
- Physical constants
- Standard orbits (LEO, GEO, GPS, ISS)
- Hale textbook example data
- Real mission parameters
"""

import pytest
import numpy as np


# =============================================================================
# Physical Constants
# =============================================================================

@pytest.fixture
def mu_earth():
    """Earth gravitational parameter [km³/s²]."""
    return 398600.4418


@pytest.fixture
def mu_sun():
    """Sun gravitational parameter [km³/s²]."""
    return 1.32712440018e11


@pytest.fixture
def r_earth():
    """Earth equatorial radius [km]."""
    return 6378.137


# =============================================================================
# Standard Orbits
# =============================================================================

@pytest.fixture
def leo_300():
    """Circular LEO at 300 km altitude."""
    return {
        'altitude': 300,  # km
        'radius': 6678,  # km
        'a': 6678,  # km
        'e': 0.0,
        'v': 7.7258,  # km/s (circular velocity)
        'period': 5431,  # s (~90.5 min)
    }


@pytest.fixture
def geo():
    """Geostationary orbit."""
    return {
        'altitude': 35786,  # km
        'radius': 42164,  # km
        'a': 42164,  # km
        'e': 0.0,
        'i': 0.0,  # rad
        'v': 3.0746,  # km/s
        'period': 86164,  # s (sidereal day)
    }


@pytest.fixture
def gps():
    """GPS satellite orbit."""
    return {
        'altitude': 20180,  # km
        'radius': 26558,  # km
        'a': 26558,  # km
        'e': 0.0,
        'i': np.radians(55),  # rad
        'period': 43082,  # s (~11h 58m)
    }


@pytest.fixture
def iss():
    """International Space Station orbit (typical)."""
    return {
        'altitude': 420,  # km (varies 408-420)
        'radius': 6798,  # km
        'a': 6798,  # km
        'e': 0.0005,  # nearly circular
        'i': np.radians(51.6),  # rad
        'period': 5561,  # s (~92.7 min)
    }


# =============================================================================
# Hale Textbook Examples
# =============================================================================

@pytest.fixture
def hale_example_2_1():
    """Hale Example 2.1: Earth satellite orbit determination."""
    return {
        'r': 8000,  # km
        'v': 7.5,  # km/s
        'mu': 398600.4418,
        'expected': {
            'a': 9696,  # km (approximate)
            'e': 0.175,  # approximate
        }
    }


@pytest.fixture
def hale_example_4_1():
    """Hale Example 4.1: State vector to orbital elements."""
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
def hale_example_4_2():
    """Hale Example 4.2: Orbital elements to state vector."""
    return {
        'a': 8000,  # km
        'e': 0.2,
        'i': np.radians(40),
        'raan': np.radians(60),
        'omega': np.radians(30),
        'nu': np.radians(50),
        'mu': 398600.4418,
    }


@pytest.fixture
def hale_example_4_3():
    """Hale Example 4.3: Kepler's equation."""
    return {
        'e': 0.4,
        'M': np.radians(30),  # 30 degrees
        'expected_E': np.radians(37.48),  # 37.48 degrees
    }


# =============================================================================
# Maneuver Examples
# =============================================================================

@pytest.fixture
def hohmann_leo_to_geo():
    """Standard LEO to GEO Hohmann transfer."""
    return {
        'r1': 6678,  # km (300 km altitude)
        'r2': 42164,  # km (GEO)
        'mu': 398600.4418,
        'expected': {
            'dv1': 2.426,  # km/s
            'dv2': 1.467,  # km/s
            'dv_total': 3.893,  # km/s
            'tof': 19077,  # s (~5.3 hours, half period)
        }
    }


# =============================================================================
# Real Mission Data
# =============================================================================

@pytest.fixture
def apollo_11():
    """Apollo 11 mission parameters."""
    return {
        'parking_orbit_altitude': 185,  # km
        'parking_orbit_radius': 6563,  # km
        'tli_dv': 3.05,  # km/s (Trans-Lunar Injection)
        'transit_time': 3 * 86400,  # s (~3 days)
        'loi_dv': 0.89,  # km/s (Lunar Orbit Insertion)
        'lunar_parking_altitude': 100,  # km
    }


@pytest.fixture
def mars_hohmann():
    """Typical Earth-Mars Hohmann transfer."""
    return {
        'r_earth': 1.0,  # AU
        'r_mars': 1.524,  # AU
        'mu_sun': 1.32712440018e11,  # km³/s²
        'expected': {
            'transfer_time': 259 * 86400,  # s (~259 days)
            'c3': 8.6,  # km²/s² (approximate)
            'v_inf_arrival': 2.65,  # km/s (approximate)
        }
    }


# =============================================================================
# Tolerance Helpers
# =============================================================================

@pytest.fixture
def tol():
    """Standard tolerances for comparisons."""
    return {
        'position': 1e-6,  # relative
        'velocity': 1e-6,  # relative
        'angle': 1e-6,  # relative
        'time': 1e-6,  # relative
        'dv': 1e-4,  # relative (maneuvers)
        'abs_position': 1.0,  # km
        'abs_velocity': 0.001,  # km/s
        'abs_angle': np.radians(0.001),  # rad
    }
