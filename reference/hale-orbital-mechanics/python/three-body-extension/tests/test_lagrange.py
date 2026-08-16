"""
Tests for Lagrange point calculations.
"""

import pytest
import numpy as np
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from threebody.lagrange import (
    lagrange_point_L1,
    lagrange_point_L2,
    lagrange_point_L3,
    lagrange_point_L4,
    lagrange_point_L5,
    lagrange_points,
    is_L4_L5_stable,
    linearized_dynamics_at_lagrange,
    classify_lagrange_point,
    distance_from_primary2_to_L1,
    distance_from_primary2_to_L2,
)
from threebody.cr3bp import pseudo_potential_derivatives


class TestCollinearLagrangePoints:
    """Tests for L1, L2, L3 calculations."""

    def test_L1_between_primaries(self, mu_earth_moon):
        """L1 should be between the two primaries."""
        mu = mu_earth_moon
        L1 = lagrange_point_L1(mu)

        assert -mu < L1[0] < 1 - mu, "L1 should be between primaries"
        assert L1[1] == 0.0, "L1 should be on x-axis"
        assert L1[2] == 0.0, "L1 should be in xy-plane"

    def test_L2_beyond_primary2(self, mu_earth_moon):
        """L2 should be beyond the smaller primary."""
        mu = mu_earth_moon
        L2 = lagrange_point_L2(mu)

        assert L2[0] > 1 - mu, "L2 should be beyond primary 2"
        assert L2[1] == 0.0, "L2 should be on x-axis"

    def test_L3_opposite_side(self, mu_earth_moon):
        """L3 should be on opposite side from primary 2."""
        mu = mu_earth_moon
        L3 = lagrange_point_L3(mu)

        assert L3[0] < -mu, "L3 should be opposite primary 2"
        assert L3[1] == 0.0, "L3 should be on x-axis"

    def test_equilibrium_L1(self, mu_earth_moon):
        """L1 should be an equilibrium point."""
        mu = mu_earth_moon
        L1 = lagrange_point_L1(mu)
        dOmega = pseudo_potential_derivatives(L1[0], L1[1], L1[2], mu)
        np.testing.assert_almost_equal(dOmega, [0, 0, 0], decimal=6)

    def test_equilibrium_L2(self, mu_earth_moon):
        """L2 should be an equilibrium point."""
        mu = mu_earth_moon
        L2 = lagrange_point_L2(mu)
        dOmega = pseudo_potential_derivatives(L2[0], L2[1], L2[2], mu)
        np.testing.assert_almost_equal(dOmega, [0, 0, 0], decimal=8)

    def test_equilibrium_L3(self, mu_earth_moon):
        """L3 should be an equilibrium point."""
        mu = mu_earth_moon
        L3 = lagrange_point_L3(mu)
        dOmega = pseudo_potential_derivatives(L3[0], L3[1], L3[2], mu)
        np.testing.assert_almost_equal(dOmega, [0, 0, 0], decimal=8)


class TestTriangularLagrangePoints:
    """Tests for L4 and L5 calculations."""

    def test_L4_equilateral(self, mu_earth_moon):
        """L4 should form equilateral triangle with primaries."""
        mu = mu_earth_moon
        L4 = lagrange_point_L4(mu)

        # Distance to primary 1 (at -mu, 0)
        d1 = np.sqrt((L4[0] + mu)**2 + L4[1]**2)
        # Distance to primary 2 (at 1-mu, 0)
        d2 = np.sqrt((L4[0] - 1 + mu)**2 + L4[1]**2)
        # Distance between primaries is 1

        np.testing.assert_almost_equal(d1, 1.0, decimal=10)
        np.testing.assert_almost_equal(d2, 1.0, decimal=10)

    def test_L5_equilateral(self, mu_earth_moon):
        """L5 should form equilateral triangle with primaries."""
        mu = mu_earth_moon
        L5 = lagrange_point_L5(mu)

        d1 = np.sqrt((L5[0] + mu)**2 + L5[1]**2)
        d2 = np.sqrt((L5[0] - 1 + mu)**2 + L5[1]**2)

        np.testing.assert_almost_equal(d1, 1.0, decimal=10)
        np.testing.assert_almost_equal(d2, 1.0, decimal=10)

    def test_L4_L5_symmetric(self, mu_earth_moon):
        """L4 and L5 should be symmetric about x-axis."""
        mu = mu_earth_moon
        L4 = lagrange_point_L4(mu)
        L5 = lagrange_point_L5(mu)

        np.testing.assert_almost_equal(L4[0], L5[0], decimal=10)
        np.testing.assert_almost_equal(L4[1], -L5[1], decimal=10)

    def test_equilibrium_L4(self, mu_earth_moon):
        """L4 should be an equilibrium point."""
        mu = mu_earth_moon
        L4 = lagrange_point_L4(mu)
        dOmega = pseudo_potential_derivatives(L4[0], L4[1], L4[2], mu)
        np.testing.assert_almost_equal(dOmega, [0, 0, 0], decimal=8)

    def test_equilibrium_L5(self, mu_earth_moon):
        """L5 should be an equilibrium point."""
        mu = mu_earth_moon
        L5 = lagrange_point_L5(mu)
        dOmega = pseudo_potential_derivatives(L5[0], L5[1], L5[2], mu)
        np.testing.assert_almost_equal(dOmega, [0, 0, 0], decimal=8)


class TestAllLagrangePoints:
    """Tests for lagrange_points() function."""

    def test_returns_five_points(self, mu_earth_moon):
        """Should return exactly 5 Lagrange points."""
        L = lagrange_points(mu_earth_moon)
        assert len(L) == 5

    def test_ordering(self, mu_earth_moon):
        """Points should be in order L1, L2, L3, L4, L5."""
        mu = mu_earth_moon
        L = lagrange_points(mu)

        # L1 between primaries
        assert -mu < L[0][0] < 1 - mu
        # L2 beyond primary 2
        assert L[1][0] > 1 - mu
        # L3 opposite side
        assert L[2][0] < -mu
        # L4 above x-axis
        assert L[3][1] > 0
        # L5 below x-axis
        assert L[4][1] < 0


class TestStability:
    """Tests for stability analysis of Lagrange points."""

    def test_L4_L5_stable_for_earth_moon(self, mu_earth_moon):
        """L4/L5 should be stable for Earth-Moon system."""
        assert is_L4_L5_stable(mu_earth_moon)

    def test_L4_L5_stable_for_sun_earth(self, mu_sun_earth):
        """L4/L5 should be stable for Sun-Earth system."""
        assert is_L4_L5_stable(mu_sun_earth)

    def test_L4_L5_unstable_for_large_mu(self):
        """L4/L5 should be unstable for μ > 0.0385."""
        large_mu = 0.1  # Larger than critical
        assert not is_L4_L5_stable(large_mu)

    def test_collinear_unstable(self, mu_earth_moon):
        """L1, L2, L3 should all be unstable."""
        mu = mu_earth_moon

        for i, L in enumerate([lagrange_point_L1(mu), lagrange_point_L2(mu), lagrange_point_L3(mu)]):
            A, eigenvalues = linearized_dynamics_at_lagrange(L, mu)
            classification = classify_lagrange_point(eigenvalues)
            assert "unstable" in classification, f"L{i+1} should be unstable"

    def test_eigenvalue_count(self, mu_earth_moon):
        """Should have 6 eigenvalues."""
        mu = mu_earth_moon
        L1 = lagrange_point_L1(mu)
        A, eigenvalues = linearized_dynamics_at_lagrange(L1, mu)
        assert len(eigenvalues) == 6


class TestDistances:
    """Tests for distance calculations."""

    def test_L1_closer_than_L2(self, mu_earth_moon):
        """L1 should be closer to primary 2 than L2."""
        mu = mu_earth_moon
        d_L1 = distance_from_primary2_to_L1(mu)
        d_L2 = distance_from_primary2_to_L2(mu)
        assert d_L1 < d_L2

    def test_sun_earth_L2_distance(self, mu_sun_earth):
        """Sun-Earth L2 should be about 0.01 in normalized units."""
        mu = mu_sun_earth
        d = distance_from_primary2_to_L2(mu)
        # L2 is about 1% of Sun-Earth distance from Earth
        assert 0.005 < d < 0.015, f"L2 distance: {d}"
