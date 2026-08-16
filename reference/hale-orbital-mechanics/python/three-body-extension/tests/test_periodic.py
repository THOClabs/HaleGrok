"""
Tests for periodic orbit computation (periodic.py).

The genuine Earth-Moon L1 Lyapunov orbit used here comes from the
session-scoped ``em_l1_lyapunov`` fixture in conftest.py, which seeds the
oracle's differential correction with a well-conditioned initial guess.
The same orbit backs validation/data/floquet.csv.

Known oracle defects are pinned with strict xfail tests (they must not be
"fixed" silently): find_lyapunov_orbit collapses to the L1 equilibrium,
find_halo_orbit loses its out-of-plane amplitude, and continue_family
degenerates instead of tracing the family.
"""

import os
import sys

import numpy as np
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from threebody.constants import MU_EARTH_MOON
from threebody.cr3bp import jacobi_at_lagrange_point, jacobi_constant
from threebody.integrators import propagate
from threebody.lagrange import lagrange_point_L1, lagrange_point_L2
from threebody.periodic import (
    PeriodicOrbit,
    continue_family,
    find_halo_orbit,
    find_lyapunov_orbit,
    lyapunov_initial_guess,
    richardson_halo_initial_guess,
)


class TestLyapunovInitialGuess:
    """Sanity checks for lyapunov_initial_guess."""

    def test_l1_guess_structure(self, mu_earth_moon):
        """L1 guess starts on the x-axis, offset by +Ax from L1."""
        mu = mu_earth_moon
        ax = 0.02
        state0, period_guess = lyapunov_initial_guess(mu, ax, L_point=1)
        x_l1 = lagrange_point_L1(mu)[0]

        assert state0.shape == (6,)
        assert state0[1] == 0.0 and state0[2] == 0.0
        assert state0[3] == 0.0 and state0[5] == 0.0
        assert state0[0] == pytest.approx(x_l1 + ax, rel=1e-12)
        assert np.isfinite(period_guess) and period_guess > 0

    def test_l2_guess_structure(self, mu_earth_moon):
        """L2 guess starts on the x-axis, offset by -Ax from L2."""
        mu = mu_earth_moon
        ax = 0.02
        state0, period_guess = lyapunov_initial_guess(mu, ax, L_point=2)
        x_l2 = lagrange_point_L2(mu)[0]

        assert state0[0] == pytest.approx(x_l2 - ax, rel=1e-12)
        assert period_guess > 0

    def test_l3_not_implemented(self, mu_earth_moon):
        """L3 Lyapunov guesses are documented as unimplemented."""
        with pytest.raises(ValueError):
            lyapunov_initial_guess(mu_earth_moon, 0.02, L_point=3)

    def test_velocity_scales_with_amplitude(self, mu_earth_moon):
        """The guessed vy0 is proportional to the requested amplitude."""
        mu = mu_earth_moon
        small, _ = lyapunov_initial_guess(mu, 0.01, L_point=1)
        large, _ = lyapunov_initial_guess(mu, 0.02, L_point=1)
        assert large[4] == pytest.approx(2.0 * small[4], rel=1e-12)


class TestRichardsonHaloGuess:
    """Sanity checks for richardson_halo_initial_guess."""

    def test_northern_guess_structure(self, mu_earth_moon):
        """Northern guess: perpendicular x-z start with z0 = +Az near L1."""
        mu = mu_earth_moon
        az = 0.05
        state0, period_guess = richardson_halo_initial_guess(
            mu, az, L_point=1, northern=True
        )
        x_l1 = lagrange_point_L1(mu)[0]

        assert state0.shape == (6,)
        assert state0[2] == pytest.approx(az)
        assert state0[1] == 0.0 and state0[3] == 0.0 and state0[5] == 0.0
        assert abs(state0[0] - x_l1) < 0.2
        assert np.isfinite(period_guess) and period_guess > 0

    def test_southern_mirror(self, mu_earth_moon):
        """Southern guess mirrors the northern one through the x-y plane."""
        mu = mu_earth_moon
        az = 0.05
        north, t_north = richardson_halo_initial_guess(mu, az, L_point=1, northern=True)
        south, t_south = richardson_halo_initial_guess(mu, az, L_point=1, northern=False)

        assert south[2] == pytest.approx(-north[2], rel=1e-12)
        assert south[0] == pytest.approx(north[0], rel=1e-12)
        assert south[4] == pytest.approx(north[4], rel=1e-12)
        assert t_south == pytest.approx(t_north, rel=1e-12)

    def test_l2_guess_near_l2(self, mu_earth_moon):
        """L2 guess sits near the L2 point."""
        mu = mu_earth_moon
        state0, _ = richardson_halo_initial_guess(mu, 0.05, L_point=2, northern=True)
        x_l2 = lagrange_point_L2(mu)[0]
        assert abs(state0[0] - x_l2) < 0.2


class TestL1LyapunovOrbit:
    """A genuine differential-corrected Lyapunov orbit about Earth-Moon L1."""

    def test_converged_periodic_orbit(self, em_l1_lyapunov):
        orbit = em_l1_lyapunov["orbit"]
        assert isinstance(orbit, PeriodicOrbit)
        assert orbit.orbit_type == "lyapunov"
        assert orbit.family == "L1"
        assert 2.0 < orbit.period < 4.0

    def test_initial_state_is_perpendicular_crossing(self, em_l1_lyapunov):
        """Initial state is a perpendicular x-axis crossing (planar)."""
        state = em_l1_lyapunov["orbit"].initial_state
        assert state[1] == 0.0 and state[2] == 0.0
        assert state[3] == 0.0 and state[5] == 0.0
        assert state[4] > 0.0

    def test_not_the_equilibrium(self, em_l1_lyapunov):
        """The correction produced a real orbit, not the L1 fixed point."""
        orbit = em_l1_lyapunov["orbit"]
        assert abs(orbit.initial_state[4]) > 0.01
        assert abs(orbit.initial_state[0] - em_l1_lyapunov["x_l1"]) > 0.01

    def test_half_period_crossing_residual(self, em_l1_lyapunov):
        """At T/2 the orbit re-crosses the x-axis perpendicularly."""
        orbit = em_l1_lyapunov["orbit"]
        mu = em_l1_lyapunov["mu"]
        result = propagate(
            orbit.initial_state, (0.0, orbit.period / 2.0), mu,
            method="RK45", tol=1e-12, max_step=0.01,
        )
        half_state = result.y[-1, :6]
        assert abs(half_state[1]) < 1e-6, "y(T/2) should vanish"
        assert abs(half_state[3]) < 1e-6, "vx(T/2) should vanish"

    def test_orbit_closes_after_one_period(self, em_l1_lyapunov):
        orbit = em_l1_lyapunov["orbit"]
        mu = em_l1_lyapunov["mu"]
        result = propagate(
            orbit.initial_state, (0.0, orbit.period), mu,
            method="RK45", tol=1e-12, max_step=0.01,
        )
        closure = np.max(np.abs(result.y[-1, :6] - orbit.initial_state))
        assert closure < 1e-8, f"orbit does not close: {closure:.3e}"

    def test_x_axis_mirror_symmetry(self, em_l1_lyapunov):
        """Lyapunov orbits are symmetric about the x-axis."""
        orbit = em_l1_lyapunov["orbit"]
        mu = em_l1_lyapunov["mu"]
        result = propagate(
            orbit.initial_state, (0.0, orbit.period), mu,
            method="RK45", tol=1e-12, max_step=0.01,
        )
        y = result.y[:, 1]
        assert np.max(y) == pytest.approx(-np.min(y), abs=1e-4)
        assert np.all(result.y[:, 2] == 0.0), "planar orbit must stay planar"

    def test_jacobi_constant_consistent(self, em_l1_lyapunov):
        """Stored Jacobi matches the state and lies below C(L1)."""
        orbit = em_l1_lyapunov["orbit"]
        mu = em_l1_lyapunov["mu"]
        c_orbit = jacobi_constant(orbit.initial_state, mu)
        c_l1 = jacobi_at_lagrange_point(lagrange_point_L1(mu), mu)

        assert orbit.jacobi == pytest.approx(c_orbit, rel=1e-12)
        assert 3.0 < orbit.jacobi < c_l1


@pytest.mark.slow
class TestFindLyapunovOrbit:
    """End-to-end find_lyapunov_orbit runs (slow: built-in crude guess)."""

    @pytest.fixture(scope="class")
    def l2_orbit(self):
        return find_lyapunov_orbit(MU_EARTH_MOON, 0.01, L_point=2, tol=1e-10)

    def test_l2_converges_to_genuine_orbit(self, l2_orbit):
        """At L2 the built-in guess has the right vy0 sign and converges."""
        assert l2_orbit is not None
        assert l2_orbit.period > 0
        assert abs(l2_orbit.initial_state[4]) > 1e-3, "degenerate orbit"
        x_l2 = lagrange_point_L2(MU_EARTH_MOON)[0]
        assert l2_orbit.initial_state[0] < x_l2, "orbit should start inside L2"

    def test_l2_orbit_closes(self, l2_orbit):
        assert l2_orbit is not None
        result = propagate(
            l2_orbit.initial_state, (0.0, l2_orbit.period), MU_EARTH_MOON,
            method="RK45", tol=1e-12, max_step=0.01,
        )
        closure = np.max(np.abs(result.y[-1, :6] - l2_orbit.initial_state))
        assert closure < 1e-6, f"orbit does not close: {closure:.3e}"

    @pytest.mark.xfail(
        strict=True,
        reason="Known oracle defect: lyapunov_initial_guess uses vy0=+0.2*Ax "
               "(wrong sign for L1), and differential_correction_planar leaves "
               "both x0 and vy0 free, so the Newton iteration collapses to the "
               "L1 equilibrium point (vy0 ~ 1e-12) yet still reports success.",
    )
    def test_l1_produces_genuine_orbit(self):
        orbit = find_lyapunov_orbit(MU_EARTH_MOON, 0.01, L_point=1, tol=1e-10)
        assert orbit is not None
        assert abs(orbit.initial_state[4]) > 1e-6, "collapsed to the equilibrium"


@pytest.mark.slow
class TestFindHaloOrbit:
    """End-to-end find_halo_orbit runs (slow)."""

    @pytest.fixture(scope="class")
    def halo_orbit(self):
        return find_halo_orbit(MU_EARTH_MOON, 0.02, L_point=1, northern=True, tol=1e-8)

    def test_reports_convergence(self, halo_orbit):
        """find_halo_orbit returns a converged PeriodicOrbit object."""
        assert halo_orbit is not None
        assert halo_orbit.orbit_type == "halo_north"
        assert halo_orbit.period > 0
        assert np.all(np.isfinite(halo_orbit.initial_state))
        assert np.isfinite(halo_orbit.jacobi)

    @pytest.mark.xfail(
        strict=True,
        reason="Known oracle defect: differential_correction_3d drifts away "
               "from the Richardson seed and collapses the out-of-plane "
               "amplitude to z0 ~ 1e-12, returning a planar orbit labelled "
               "'halo_north'.",
    )
    def test_halo_has_out_of_plane_amplitude(self, halo_orbit):
        assert halo_orbit is not None
        assert abs(halo_orbit.initial_state[2]) > 1e-6, "no z-amplitude: not a halo"


@pytest.mark.slow
class TestContinueFamily:
    """Pseudo-continuation of the Lyapunov family (slow)."""

    @pytest.fixture(scope="class")
    def family(self, em_l1_lyapunov):
        return continue_family(
            em_l1_lyapunov["orbit"],
            em_l1_lyapunov["mu"],
            parameter="amplitude",
            delta=0.005,
            n_orbits=2,
        )

    def test_family_starts_with_seed(self, family, em_l1_lyapunov):
        assert len(family) >= 2
        assert family[0] is em_l1_lyapunov["orbit"]

    def test_monotone_continuation_parameter(self, family):
        """The continuation parameter (scaled x0) increases monotonically."""
        x0_values = [orbit.initial_state[0] for orbit in family]
        assert all(b > a for a, b in zip(x0_values, x0_values[1:])), (
            f"x0 not monotone along family: {x0_values}"
        )
        assert all(orbit.period > 0 for orbit in family)

    @pytest.mark.xfail(
        strict=True,
        reason="Known oracle defect: continue_family's differential_correction_3d "
               "collapses continued members onto the L1 equilibrium "
               "(vy0 ~ 1e-9), so the 'family' degenerates after the seed orbit.",
    )
    def test_family_members_are_genuine_orbits(self, family):
        assert len(family) >= 2
        for orbit in family[1:]:
            assert abs(orbit.initial_state[4]) > 1e-6, (
                f"degenerate family member: vy0={orbit.initial_state[4]:.3e}"
            )
