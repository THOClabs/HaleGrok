"""
Shared test fixtures for Three-Body Extension.

Provides common test data including:
- System mass ratios
- Known Lagrange point positions
- Reference periodic orbits
- Validation data from real missions
"""

import pytest
import numpy as np
import sys
import os

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))


# =============================================================================
# Mass Ratios
# =============================================================================

@pytest.fixture
def mu_earth_moon():
    """Earth-Moon mass ratio."""
    return 0.01215058560962404


@pytest.fixture
def mu_sun_earth():
    """Sun-Earth mass ratio."""
    return 3.003480593e-6


@pytest.fixture
def mu_sun_jupiter():
    """Sun-Jupiter mass ratio."""
    return 9.537e-4


# =============================================================================
# Lagrange Point Reference Values
# =============================================================================

@pytest.fixture
def sun_earth_lagrange_points():
    """
    Sun-Earth Lagrange points (normalized coordinates).

    Reference: JPL Solar System Dynamics
    """
    return {
        'L1': {'x': 0.9899846, 'distance_from_earth_km': 1.5e6},
        'L2': {'x': 1.0100754, 'distance_from_earth_km': 1.5e6},
        'L3': {'x': -1.0000012, 'distance_from_earth_km': 1.5e8},
        'L4': {'x': 0.5, 'y': 0.866025},
        'L5': {'x': 0.5, 'y': -0.866025},
    }


@pytest.fixture
def earth_moon_lagrange_points():
    """
    Earth-Moon Lagrange points (normalized coordinates).
    """
    return {
        'L1': {'x': 0.8369, 'distance_from_moon_km': 58000},
        'L2': {'x': 1.1557, 'distance_from_moon_km': 64500},
    }


# =============================================================================
# Standard Test States
# =============================================================================

@pytest.fixture
def simple_orbit_state():
    """A simple test state near L2."""
    return np.array([1.0, 0.0, 0.0, 0.0, 0.2, 0.0])


@pytest.fixture
def halo_orbit_initial_guess():
    """Initial guess for Earth-Moon L2 halo orbit."""
    return {
        'state': np.array([1.1, 0.0, 0.05, 0.0, -0.2, 0.0]),
        'period_guess': 3.0,
    }


# =============================================================================
# Real Mission Data
# =============================================================================

@pytest.fixture
def jwst_orbit():
    """
    JWST orbit parameters at Sun-Earth L2.

    Reference: NASA JWST Mission
    """
    return {
        'system': 'sun-earth',
        'L_point': 2,
        'distance_from_earth_km': 1.5e6,
        'orbit_type': 'halo',
        'period_days': 180,  # Approximate
        'az_amplitude_km': 250000,
        'station_keeping_dv_m_s_per_year': 2.5,  # Approximate
    }


@pytest.fixture
def lunar_gateway():
    """
    Lunar Gateway orbit parameters at Earth-Moon L2.

    Reference: NASA Artemis Program
    """
    return {
        'system': 'earth-moon',
        'L_point': 2,
        'orbit_type': 'near_rectilinear_halo',
        'period_days': 6.5,
        'periselene_km': 3000,
        'aposelene_km': 70000,
    }


@pytest.fixture
def artemis_mission():
    """
    ARTEMIS mission parameters.

    First spacecraft to orbit Earth-Moon L1 and L2.
    """
    return {
        'L1_orbit_period_days': 14,
        'L2_orbit_period_days': 14,
        'transfer_time_days': 5,
    }


# =============================================================================
# Tolerance Helpers
# =============================================================================

@pytest.fixture
def tol():
    """Standard tolerances for comparisons."""
    return {
        'position': 1e-6,         # Relative tolerance for position
        'velocity': 1e-6,         # Relative tolerance for velocity
        'jacobi': 1e-10,          # Jacobi constant conservation
        'lagrange': 1e-8,         # Lagrange point position
        'period': 1e-6,           # Orbital period
        'eigenvalue': 1e-4,       # Eigenvalue comparisons
    }


# =============================================================================
# Helper Functions
# =============================================================================

@pytest.fixture
def assert_state_close():
    """Helper to compare state vectors."""
    def _assert(state1, state2, rtol=1e-6, atol=1e-10):
        np.testing.assert_allclose(state1[:3], state2[:3], rtol=rtol, atol=atol,
                                   err_msg="Position mismatch")
        np.testing.assert_allclose(state1[3:6], state2[3:6], rtol=rtol, atol=atol,
                                   err_msg="Velocity mismatch")
    return _assert


@pytest.fixture
def assert_jacobi_conserved():
    """Helper to verify Jacobi constant conservation."""
    def _assert(jacobi_array, tol=1e-10):
        C0 = jacobi_array[0]
        max_deviation = np.max(np.abs(jacobi_array - C0))
        assert max_deviation < tol, \
            f"Jacobi constant not conserved: max deviation = {max_deviation}"
    return _assert


# =============================================================================
# Shared Earth-Moon L1 Lyapunov Orbit (used by test_periodic and test_stability)
# =============================================================================

@pytest.fixture(scope="session")
def em_l1_lyapunov():
    """
    A genuine planar Lyapunov orbit about Earth-Moon L1 (session-scoped).

    periodic.find_lyapunov_orbit's built-in initial guess (vy0 = +0.2*Ax)
    collapses to the L1 equilibrium point (see the xfail test in
    test_periodic.py), so this fixture seeds the oracle's
    differential_correction_planar with a vy0 refined by a 1-D root solve on
    the perpendicular-crossing residual vx(T/2).  This mirrors
    validation/generate_reference.py, which produces the committed
    validation/data/floquet.csv reference from the same orbit.

    The orbit starts at the LEFT x-extreme (x0 = xL1 - Ax with vy0 > 0) so
    that the first downward y=0 crossing used by the differential correction
    is the true half period.

    Returns a dict with keys: orbit (PeriodicOrbit), mu, x_l1, ax.
    """
    from scipy.optimize import brentq

    from threebody.constants import MU_EARTH_MOON
    from threebody.cr3bp import jacobi_constant
    from threebody.integrators import propagate_with_events
    from threebody.lagrange import lagrange_point_L1
    from threebody.periodic import PeriodicOrbit, differential_correction_planar

    mu = MU_EARTH_MOON
    ax = 0.02
    x_l1 = lagrange_point_L1(mu)[0]
    x0 = x_l1 - ax

    def downward_y_crossing(t, y):
        return y[1]

    downward_y_crossing.terminal = True
    downward_y_crossing.direction = -1.0

    def vx_at_first_crossing(vy0):
        state = np.array([x0, 0.0, 0.0, 0.0, vy0, 0.0])
        # Start at t=1e-8: y(0)=0 sits exactly on the event surface.
        result = propagate_with_events(
            state, (1e-8, 6.0), mu, [downward_y_crossing], rtol=1e-12, atol=1e-12
        )
        return result.y[-1, 3], result.t[-1]

    # Bracket verified for ax=0.02: vx(T/2) changes sign on (0.185, 0.205).
    vy_seed = brentq(lambda v: vx_at_first_crossing(v)[0], 0.185, 0.205, xtol=1e-13)
    _, t_half_seed = vx_at_first_crossing(vy_seed)

    seed = np.array([x0, 0.0, 0.0, 0.0, vy_seed, 0.0])
    state, period, converged = differential_correction_planar(
        seed, t_half_seed, mu, tol=1e-10, max_iter=60
    )
    assert converged, "differential_correction_planar failed from a refined seed"

    orbit = PeriodicOrbit(
        initial_state=state,
        period=float(period),
        jacobi=float(jacobi_constant(state, mu)),
        orbit_type="lyapunov",
        family="L1",
    )
    return {"orbit": orbit, "mu": mu, "x_l1": x_l1, "ax": ax}
