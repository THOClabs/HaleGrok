"""
Tests for CR3BP equations of motion and related functions.
"""

import pytest
import numpy as np
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from threebody.cr3bp import (
    pseudo_potential,
    pseudo_potential_derivatives,
    equations_of_motion,
    jacobi_constant,
    effective_potential,
    zero_velocity_curve,
    state_in_rotating_frame,
    state_in_inertial_frame,
)


class TestPseudoPotential:
    """Tests for pseudo-potential calculation."""

    def test_at_primary1(self, mu_earth_moon):
        """Potential should be very large near primary 1."""
        mu = mu_earth_moon
        # Near primary 1 (larger body at x = -mu)
        x, y, z = -mu + 0.001, 0, 0  # Closer to primary
        omega = pseudo_potential(x, y, z, mu)
        assert omega > 50, "Potential should be large near primary"

    def test_at_primary2(self, mu_earth_moon):
        """Potential should be very large near primary 2."""
        mu = mu_earth_moon
        # Near primary 2 (smaller body at x = 1-mu)
        x, y, z = 1 - mu + 0.001, 0, 0  # Closer to primary
        omega = pseudo_potential(x, y, z, mu)
        assert omega > 10, "Potential should be larger near primary"

    def test_at_L4(self, mu_earth_moon):
        """Test potential at L4 triangular point."""
        mu = mu_earth_moon
        x, y, z = 0.5 - mu, np.sqrt(3)/2, 0
        omega = pseudo_potential(x, y, z, mu)
        # L4 potential should be around 1.5 for small mu
        assert 1.0 < omega < 2.0, f"L4 potential unexpected: {omega}"

    def test_symmetry_xy(self, mu_sun_earth):
        """Potential should be symmetric about y=0 in x-y plane."""
        mu = mu_sun_earth
        x, z = 0.5, 0
        omega_pos = pseudo_potential(x, 0.3, z, mu)
        omega_neg = pseudo_potential(x, -0.3, z, mu)
        np.testing.assert_almost_equal(omega_pos, omega_neg, decimal=10)


class TestPseudoPotentialDerivatives:
    """Tests for partial derivatives of pseudo-potential."""

    def test_at_lagrange_point(self, mu_earth_moon):
        """Derivatives should be zero at Lagrange points."""
        from threebody.lagrange import lagrange_point_L4
        mu = mu_earth_moon
        L4 = lagrange_point_L4(mu)
        dOmega = pseudo_potential_derivatives(L4[0], L4[1], L4[2], mu)
        np.testing.assert_almost_equal(dOmega, [0, 0, 0], decimal=8)

    def test_numerical_derivative(self, mu_earth_moon):
        """Compare analytical derivatives to numerical."""
        mu = mu_earth_moon
        x, y, z = 0.5, 0.3, 0.1
        h = 1e-7

        # Analytical
        dx, dy, dz = pseudo_potential_derivatives(x, y, z, mu)

        # Numerical
        dx_num = (pseudo_potential(x+h, y, z, mu) - pseudo_potential(x-h, y, z, mu)) / (2*h)
        dy_num = (pseudo_potential(x, y+h, z, mu) - pseudo_potential(x, y-h, z, mu)) / (2*h)
        dz_num = (pseudo_potential(x, y, z+h, mu) - pseudo_potential(x, y, z-h, mu)) / (2*h)

        np.testing.assert_almost_equal(dx, dx_num, decimal=5)
        np.testing.assert_almost_equal(dy, dy_num, decimal=5)
        np.testing.assert_almost_equal(dz, dz_num, decimal=5)


class TestEquationsOfMotion:
    """Tests for CR3BP equations of motion."""

    def test_output_shape(self, mu_earth_moon):
        """Equations should return 6-element array."""
        state = np.array([1.0, 0.0, 0.0, 0.0, 0.1, 0.0])
        deriv = equations_of_motion(0, state, mu_earth_moon)
        assert deriv.shape == (6,)

    def test_velocity_derivatives(self, mu_earth_moon):
        """First three derivatives should be velocities."""
        state = np.array([1.0, 0.0, 0.0, 0.1, 0.2, 0.3])
        deriv = equations_of_motion(0, state, mu_earth_moon)
        np.testing.assert_array_equal(deriv[:3], state[3:6])

    def test_stationary_at_lagrange(self, mu_earth_moon):
        """Acceleration should be zero at Lagrange point with zero velocity."""
        from threebody.lagrange import lagrange_point_L2  # Use L2 (more stable numerically)
        mu = mu_earth_moon
        L2 = lagrange_point_L2(mu)
        state = np.array([L2[0], L2[1], L2[2], 0, 0, 0])
        deriv = equations_of_motion(0, state, mu)
        # Velocities are zero, accelerations should be ~zero
        np.testing.assert_almost_equal(deriv[3:6], [0, 0, 0], decimal=6)


class TestJacobiConstant:
    """Tests for Jacobi constant calculation."""

    def test_stationary_point(self, mu_earth_moon):
        """At rest, Jacobi constant is 2*Omega."""
        mu = mu_earth_moon
        x, y, z = 0.5, 0.3, 0.0
        state = np.array([x, y, z, 0, 0, 0])
        C = jacobi_constant(state, mu)
        omega = pseudo_potential(x, y, z, mu)
        np.testing.assert_almost_equal(C, 2*omega, decimal=10)

    def test_increases_with_slower_velocity(self, mu_earth_moon):
        """Jacobi constant should increase as velocity decreases."""
        mu = mu_earth_moon
        x, y, z = 0.8, 0.0, 0.0

        state_fast = np.array([x, y, z, 0, 0.5, 0])
        state_slow = np.array([x, y, z, 0, 0.1, 0])

        C_fast = jacobi_constant(state_fast, mu)
        C_slow = jacobi_constant(state_slow, mu)

        assert C_slow > C_fast, "Slower = higher Jacobi constant"


class TestCoordinateTransformations:
    """Tests for rotating/inertial frame transformations."""

    def test_roundtrip(self, mu_sun_earth):
        """Transform to inertial and back should give original."""
        r_rot = np.array([1.0, 0.5, 0.1])
        v_rot = np.array([0.1, -0.2, 0.05])
        theta = 1.5

        r_iner, v_iner = state_in_inertial_frame(r_rot, v_rot, theta)
        r_back, v_back = state_in_rotating_frame(r_iner, v_iner, theta)

        np.testing.assert_array_almost_equal(r_rot, r_back, decimal=10)
        np.testing.assert_array_almost_equal(v_rot, v_back, decimal=10)

    def test_theta_zero(self, mu_sun_earth):
        """At theta=0, frames should align."""
        r_rot = np.array([1.0, 0.5, 0.1])
        v_rot = np.array([0.1, -0.2, 0.05])
        theta = 0.0

        r_iner, v_iner = state_in_inertial_frame(r_rot, v_rot, theta)

        # Position should be same
        np.testing.assert_array_almost_equal(r_rot, r_iner, decimal=10)


class TestZeroVelocityCurve:
    """Tests for zero-velocity curve computation."""

    def test_output_shape(self, mu_earth_moon):
        """Should return 3 grids of correct size."""
        C = 3.0
        X, Y, Z = zero_velocity_curve(C, mu_earth_moon, n_points=50)
        assert X.shape == (50, 50)
        assert Y.shape == (50, 50)
        assert Z.shape == (50, 50)

    def test_zero_contour_exists(self, mu_earth_moon):
        """Should have both positive and negative Z values."""
        from threebody.lagrange import lagrange_point_jacobi_constants
        C_L2 = lagrange_point_jacobi_constants(mu_earth_moon)[1]
        X, Y, Z = zero_velocity_curve(C_L2, mu_earth_moon)
        assert np.any(Z > 0) and np.any(Z < 0), "Should have zero contour"
