"""
Tests for stability analysis (stability.py).

Uses the genuine Earth-Moon L1 Lyapunov orbit from the session-scoped
``em_l1_lyapunov`` fixture (conftest.py) — the same orbit that backs
validation/data/floquet.csv.

Expected monodromy spectrum for a planar L1 Lyapunov orbit (real 6x6
symplectic matrix): three reciprocal pairs (lambda, 1/lambda) — one
dominant real unstable pair (lambda >> 1), one trivial pair at (1, 1)
from period/energy invariance, and one further pair.  The trivial pair
is a defective 2x2 Jordan block, so numerical eigensolvers split it as
1 +/- sqrt(eps_effective) ~ 1e-6; tolerances below account for that.

Note on conventions: stability.analyze_stability defines stability_index
as max|lambda| (see StabilityInfo docstring and code), NOT the Broucke
index nu = (lambda + 1/lambda)/2.  Tests pin the module's convention.
"""

import os
import sys

import numpy as np
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from threebody.stability import (
    StabilityInfo,
    analyze_stability,
    compute_monodromy_matrix,
    eigenvalue_classification,
    stability_index_string,
)

MONODROMY_DT = 1e-4


@pytest.fixture(scope="module")
def stability(em_l1_lyapunov):
    """Full stability analysis of the shared L1 Lyapunov orbit."""
    return analyze_stability(
        em_l1_lyapunov["orbit"], em_l1_lyapunov["mu"], dt=MONODROMY_DT
    )


class TestMonodromyMatrix:
    """Structural properties of the monodromy matrix."""

    def test_shape_and_finiteness(self, stability):
        assert isinstance(stability, StabilityInfo)
        assert stability.monodromy.shape == (6, 6)
        assert np.all(np.isfinite(stability.monodromy))

    def test_determinant_is_one(self, stability):
        """Symplectic monodromy matrix has unit determinant."""
        det = np.linalg.det(stability.monodromy)
        assert det == pytest.approx(1.0, abs=1e-6)

    def test_matches_compute_monodromy_matrix(self, stability, em_l1_lyapunov):
        """analyze_stability uses compute_monodromy_matrix internally."""
        monodromy = compute_monodromy_matrix(
            em_l1_lyapunov["orbit"], em_l1_lyapunov["mu"], dt=MONODROMY_DT
        )
        np.testing.assert_allclose(
            stability.monodromy, monodromy, rtol=1e-13, atol=1e-13
        )


class TestEigenvalueStructure:
    """Floquet multiplier structure of the L1 Lyapunov orbit."""

    def test_six_eigenvalues_sorted_by_magnitude(self, stability):
        magnitudes = np.abs(stability.eigenvalues)
        assert len(stability.eigenvalues) == 6
        assert np.all(magnitudes[:-1] >= magnitudes[1:]), "not sorted descending"

    def test_reciprocal_pairs(self, stability):
        """Eigenvalues pair as (lambda_i, 1/lambda_i): products are 1."""
        ev = stability.eigenvalues  # sorted by |lambda| descending
        for i in range(3):
            product = ev[i] * ev[5 - i]
            assert abs(product - 1.0) < 1e-6, (
                f"pair ({i}, {5 - i}): lambda_i*lambda_j = {product}"
            )

    def test_trivial_unit_pair(self, stability):
        """Exactly one pair sits at (1, 1) (defective Jordan block)."""
        ev = stability.eigenvalues
        unit = ev[np.abs(np.abs(ev) - 1.0) < 1e-6]
        assert len(unit) == 2, f"expected exactly 2 unit-modulus multipliers: {ev}"
        # Product of the trivial pair is 1 to high accuracy...
        assert abs(unit[0] * unit[1] - 1.0) < 1e-8
        # ...while each member individually can split by ~sqrt(perturbation)
        # because the pair is a defective 2x2 Jordan block (hence 1e-4 here
        # rather than the 1e-6 one might expect from the integrator alone).
        for lam in unit:
            assert abs(lam - 1.0) < 1e-4, f"trivial multiplier too far from 1: {lam}"

    def test_dominant_real_unstable_pair(self, stability):
        """L1 Lyapunov orbits are strongly unstable: real lambda_max >> 1."""
        ev = stability.eigenvalues
        lam_max = ev[0]
        lam_min = ev[5]
        assert abs(lam_max.imag) < 1e-9 * abs(lam_max), "dominant multiplier not real"
        assert lam_max.real > 1.0
        assert lam_max.real > 100.0, "L1 Lyapunov orbit should be strongly unstable"
        assert abs(lam_min) < 1.0
        assert lam_min == pytest.approx(1.0 / lam_max, rel=1e-6)


class TestStabilityClassification:
    """Consistency of the derived classification fields."""

    def test_stability_index_is_max_eigenvalue_magnitude(self, stability):
        """Module convention: stability_index = max|lambda| (not Broucke nu)."""
        expected = np.max(np.abs(stability.eigenvalues))
        assert stability.stability_index == pytest.approx(expected, rel=1e-12)
        assert stability.stability_index > 1.0

    def test_is_stable_flag_consistent(self, stability):
        # Note: the module stores a numpy bool, so compare by value.
        assert bool(stability.is_stable) == bool(
            stability.stability_index <= 1.0 + 1e-6
        )
        assert not stability.is_stable, "L1 Lyapunov orbit must be unstable"

    def test_unstable_direction(self, stability):
        """Unstable direction is a unit-norm eigenvector of lambda_max."""
        u = stability.unstable_direction
        assert u is not None
        assert np.linalg.norm(u) == pytest.approx(1.0, rel=1e-12)
        lam_max = stability.eigenvalues[0].real
        residual = np.linalg.norm(stability.monodromy @ u - lam_max * u)
        assert residual < 1e-6 * abs(lam_max), f"not an eigenvector: {residual:.3e}"

    def test_stable_direction(self, stability):
        """Stable direction is a unit-norm contracting eigenvector."""
        s = stability.stable_direction
        assert s is not None
        assert np.linalg.norm(s) == pytest.approx(1.0, rel=1e-12)
        image = stability.monodromy @ s
        rayleigh = float(s @ image)  # eigenvalue estimate for a real eigenvector
        assert abs(rayleigh) < 1.0, "stable direction must contract"
        residual = np.linalg.norm(image - rayleigh * s)
        assert residual < 1e-6, f"not an eigenvector: {residual:.3e}"

    def test_human_readable_strings(self, stability):
        assert stability_index_string(stability).startswith("Unstable")
        classification = eigenvalue_classification(stability.eigenvalues)
        assert "unit" in classification
        assert "real unstable" in classification
