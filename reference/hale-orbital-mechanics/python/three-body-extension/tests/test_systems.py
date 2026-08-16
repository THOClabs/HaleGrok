"""
Tests for predefined three-body systems (systems.py).

Covers every system exposed by get_system/SYSTEMS: mass-ratio ranges,
mu/mu1/mu2 consistency, primary placement, and dimensional unit
conversion round-trips.
"""

import os
import sys

import numpy as np
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from threebody.constants import TWO_PI
from threebody.systems import EARTH_MOON, SUN_EARTH, SYSTEMS, System, get_system


def all_systems():
    return sorted(SYSTEMS.items())


class TestSystemCatalog:
    """The predefined-system registry and get_system lookup."""

    def test_catalog_not_empty(self):
        assert len(SYSTEMS) >= 3
        for expected in ("earth-moon", "sun-earth", "sun-jupiter"):
            assert expected in SYSTEMS

    @pytest.mark.parametrize("name,system", all_systems())
    def test_get_system_returns_registered_object(self, name, system):
        assert get_system(name) is system

    def test_name_normalization(self):
        """Lookup is case-insensitive and accepts spaces/underscores."""
        assert get_system("Earth-Moon") is EARTH_MOON
        assert get_system("earth_moon") is EARTH_MOON
        assert get_system("EARTH MOON") is EARTH_MOON
        assert get_system("Sun-Earth") is SUN_EARTH

    def test_unknown_system_raises(self):
        with pytest.raises(KeyError):
            get_system("earth-phobos")

    @pytest.mark.parametrize("name,system", all_systems())
    def test_repr_contains_name(self, name, system):
        assert system.name in repr(system)


class TestMassRatios:
    """Mass-ratio invariants for every predefined system."""

    @pytest.mark.parametrize("name,system", all_systems())
    def test_mass_ratio_in_range(self, name, system):
        """CR3BP convention: mu = m2/(m1+m2), smaller body second."""
        assert 0.0 < system.mu < 0.5

    @pytest.mark.parametrize("name,system", all_systems())
    def test_mu_consistent_with_mu1_mu2(self, name, system):
        assert abs(system.mu2 - system.mu) <= 1e-9 * system.mu
        assert abs(system.mu1 - (1.0 - system.mu)) <= 1e-9
        assert system.mu1 + system.mu2 == pytest.approx(1.0, abs=1e-15)

    @pytest.mark.parametrize("name,system", all_systems())
    def test_primary_positions(self, name, system):
        """m1 at (-mu, 0, 0), m2 at (1-mu, 0, 0), unit separation."""
        p1 = system.primary1_position
        p2 = system.primary2_position
        np.testing.assert_allclose(p1, [-system.mu, 0.0, 0.0], rtol=0, atol=0)
        np.testing.assert_allclose(p2, [1.0 - system.mu, 0.0, 0.0], rtol=0, atol=0)
        assert np.linalg.norm(p2 - p1) == pytest.approx(1.0, rel=1e-15)


class TestUnitConversions:
    """Dimensional/normalized unit conversions round-trip."""

    @pytest.mark.parametrize("name,system", all_systems())
    def test_all_predefined_systems_have_dimensions(self, name, system):
        """Every shipped system carries distance and period for conversions."""
        assert system.distance is not None and system.distance > 0
        assert system.period is not None and system.period > 0

    @pytest.mark.parametrize("name,system", all_systems())
    def test_length_roundtrip(self, name, system):
        for value in (0.1, 1.0, 2.5):
            km = system.to_dimensional_length(value)
            assert system.to_normalized_length(km) == pytest.approx(value, rel=1e-12)

    @pytest.mark.parametrize("name,system", all_systems())
    def test_time_roundtrip(self, name, system):
        for value in (0.5, TWO_PI):
            seconds = system.to_dimensional_time(value)
            assert system.to_normalized_time(seconds) == pytest.approx(value, rel=1e-12)

    @pytest.mark.parametrize("name,system", all_systems())
    def test_unit_definitions(self, name, system):
        """length/time/velocity units follow the CR3BP normalization."""
        assert system.length_unit == pytest.approx(system.distance, rel=1e-15)
        assert system.time_unit == pytest.approx(system.period / TWO_PI, rel=1e-12)
        assert system.velocity_unit == pytest.approx(
            system.distance / (system.period / TWO_PI), rel=1e-12
        )
        assert system.to_dimensional_velocity(1.0) == pytest.approx(
            system.velocity_unit, rel=1e-12
        )

    def test_system_without_dimensions_returns_none(self):
        """Conversions degrade gracefully when dimensions are absent."""
        bare = System(name="bare", mu=0.01)
        assert bare.to_dimensional_length(1.0) is None
        assert bare.to_dimensional_time(1.0) is None
        assert bare.to_dimensional_velocity(1.0) is None
        assert bare.to_normalized_length(1.0) is None
        assert bare.to_normalized_time(1.0) is None
        assert bare.time_unit is None and bare.velocity_unit is None


class TestDistanceHelpers:
    """distance_to_primary1/2 geometry checks."""

    @pytest.mark.parametrize("name,system", all_systems())
    def test_distances_from_primaries(self, name, system):
        at_p2 = np.array([1.0 - system.mu, 0.0, 0.0])
        assert system.distance_to_primary2(at_p2) == pytest.approx(0.0, abs=1e-15)
        assert system.distance_to_primary1(at_p2) == pytest.approx(1.0, rel=1e-12)

    @pytest.mark.parametrize("name,system", all_systems())
    def test_l4_is_equidistant(self, name, system):
        """L4 forms an equilateral triangle with both primaries."""
        l4 = np.array([0.5 - system.mu, np.sqrt(3.0) / 2.0, 0.0])
        assert system.distance_to_primary1(l4) == pytest.approx(1.0, rel=1e-12)
        assert system.distance_to_primary2(l4) == pytest.approx(1.0, rel=1e-12)
