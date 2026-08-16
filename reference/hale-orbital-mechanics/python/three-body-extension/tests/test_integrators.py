"""
Tests for numerical integration methods.
"""

import pytest
import numpy as np
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from threebody.integrators import (
    rk4_step,
    rk45_step,
    propagate_fixed_step,
    propagate_adaptive,
    propagate,
    check_jacobi_conservation,
    IntegrationResult,
)
from threebody.cr3bp import equations_of_motion, jacobi_constant


class TestRK4Step:
    """Tests for single RK4 step."""

    def test_linear_ode(self):
        """Test on simple linear ODE: dy/dt = -y."""
        def f(t, y, *args):
            return -y

        y0 = np.array([1.0])
        h = 0.1
        y1 = rk4_step(f, 0, y0, h)

        # Exact solution: y = exp(-t)
        y_exact = np.exp(-h)
        np.testing.assert_almost_equal(y1[0], y_exact, decimal=6)

    def test_preserves_shape(self, mu_earth_moon):
        """Output should have same shape as input."""
        state = np.array([1.0, 0.0, 0.0, 0.0, 0.2, 0.0])
        h = 0.001
        result = rk4_step(equations_of_motion, 0, state, h, mu_earth_moon)
        assert result.shape == state.shape


class TestRK45Step:
    """Tests for RK45 step with error estimate."""

    def test_returns_three_values(self, mu_earth_moon):
        """Should return (state, h_new, error)."""
        state = np.array([1.0, 0.0, 0.0, 0.0, 0.2, 0.0])
        h = 0.01
        y_new, h_new, error = rk45_step(
            equations_of_motion, 0, state, h, mu_earth_moon
        )
        assert y_new.shape == state.shape
        assert isinstance(h_new, float)
        assert isinstance(error, float)

    def test_error_estimate_reasonable(self, mu_earth_moon):
        """Error estimate should be small for small step."""
        state = np.array([1.0, 0.0, 0.0, 0.0, 0.2, 0.0])
        h = 0.001
        _, _, error = rk45_step(
            equations_of_motion, 0, state, h, mu_earth_moon, tol=1e-10
        )
        assert error < 1e-6, "Error should be reasonably small for small step"


class TestPropagateFixedStep:
    """Tests for fixed-step propagation."""

    def test_jacobi_conservation(self, mu_earth_moon):
        """Jacobi constant should be conserved."""
        state0 = np.array([0.8, 0.0, 0.0, 0.0, 0.5, 0.0])
        result = propagate_fixed_step(
            state0, (0, 2*np.pi), mu_earth_moon, dt=0.001
        )

        assert result.jacobi is not None
        conserved, max_dev = check_jacobi_conservation(result, tol=1e-6)
        assert conserved, f"Jacobi not conserved: max deviation = {max_dev}"

    def test_returns_correct_times(self, mu_earth_moon):
        """Time array should span requested interval."""
        state0 = np.array([1.0, 0.0, 0.0, 0.0, 0.2, 0.0])
        t_start, t_end = 0, 1.0
        result = propagate_fixed_step(
            state0, (t_start, t_end), mu_earth_moon, dt=0.1
        )

        assert result.t[0] == t_start
        assert abs(result.t[-1] - t_end) < 0.1  # Within one step

    def test_with_stm(self, mu_earth_moon):
        """Should propagate STM when requested."""
        state0 = np.array([1.0, 0.0, 0.0, 0.0, 0.2, 0.0])
        result = propagate_fixed_step(
            state0, (0, 0.5), mu_earth_moon, dt=0.01, with_stm=True
        )

        # State + 36 STM elements = 42
        assert result.y.shape[1] == 42


class TestPropagateAdaptive:
    """Tests for adaptive-step propagation."""

    def test_jacobi_conservation(self, mu_earth_moon):
        """Jacobi constant should be conserved."""
        state0 = np.array([0.8, 0.0, 0.0, 0.0, 0.5, 0.0])
        result = propagate_adaptive(
            state0, (0, 2*np.pi), mu_earth_moon, tol=1e-10
        )

        conserved, max_dev = check_jacobi_conservation(result, tol=1e-8)
        assert conserved, f"Jacobi not conserved: max deviation = {max_dev}"

    def test_success_flag(self, mu_earth_moon):
        """Should return success for normal integration."""
        state0 = np.array([1.0, 0.0, 0.0, 0.0, 0.2, 0.0])
        result = propagate_adaptive(
            state0, (0, 1.0), mu_earth_moon
        )
        assert result.success


class TestPropagate:
    """Tests for main propagate interface."""

    def test_rk4_method(self, mu_earth_moon):
        """Should use RK4 when specified."""
        state0 = np.array([1.0, 0.0, 0.0, 0.0, 0.2, 0.0])
        result = propagate(
            state0, (0, 0.5), mu_earth_moon, method="RK4", dt=0.01
        )
        assert result.success

    def test_rk45_method(self, mu_earth_moon):
        """Should use RK45 when specified."""
        state0 = np.array([1.0, 0.0, 0.0, 0.0, 0.2, 0.0])
        result = propagate(
            state0, (0, 0.5), mu_earth_moon, method="RK45"
        )
        assert result.success

    def test_invalid_method(self, mu_earth_moon):
        """Should raise error for invalid method."""
        state0 = np.array([1.0, 0.0, 0.0, 0.0, 0.2, 0.0])
        with pytest.raises(ValueError):
            propagate(state0, (0, 0.5), mu_earth_moon, method="INVALID")


class TestJacobiConservation:
    """Detailed tests for Jacobi constant conservation."""

    def test_long_integration(self, mu_earth_moon):
        """Test conservation over multiple orbital periods."""
        # Start in a reasonable orbit region
        state0 = np.array([0.5, 0.0, 0.0, 0.0, 0.8, 0.0])

        result = propagate_adaptive(
            state0, (0, 20), mu_earth_moon, tol=1e-12
        )

        conserved, max_dev = check_jacobi_conservation(result, tol=1e-8)
        assert conserved, f"Long integration: max deviation = {max_dev}"

    def test_near_primary(self, mu_earth_moon):
        """Conservation should hold even near primaries."""
        mu = mu_earth_moon
        # Start close to Moon (primary 2)
        state0 = np.array([1 - mu + 0.05, 0.0, 0.0, 0.0, 0.3, 0.0])

        result = propagate_adaptive(
            state0, (0, 2), mu_earth_moon, tol=1e-12, max_step=0.01
        )

        conserved, max_dev = check_jacobi_conservation(result, tol=1e-6)
        assert conserved, f"Near primary: max deviation = {max_dev}"
