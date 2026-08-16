"""
Pre-defined three-body gravitational systems.

Each System object contains the mass ratio μ and optional dimensional
parameters for converting between normalized and physical units.

Example
-------
>>> from threebody.systems import SUN_EARTH
>>> print(f"Mass ratio: {SUN_EARTH.mu:.6e}")
>>> L1_pos = SUN_EARTH.L1_position()
>>> L1_km = SUN_EARTH.to_dimensional_length(L1_pos)
"""

from dataclasses import dataclass
from typing import Optional, Tuple
import numpy as np

from .constants import (
    MU_SUN_EARTH,
    MU_EARTH_MOON,
    MU_SUN_JUPITER,
    MU_SUN_MARS,
    MU_SUN_VENUS,
    SUN_EARTH_DISTANCE,
    SUN_EARTH_PERIOD,
    EARTH_MOON_DISTANCE,
    EARTH_MOON_PERIOD,
    TWO_PI,
)


@dataclass
class System:
    """
    A three-body gravitational system.

    Parameters
    ----------
    name : str
        Human-readable name (e.g., "Sun-Earth")
    mu : float
        Mass ratio μ = m2/(m1+m2) where m2 is smaller primary
    distance : float, optional
        Distance between primaries in km (for dimensional conversions)
    period : float, optional
        Orbital period of primaries in seconds

    Attributes
    ----------
    mu1 : float
        1 - μ (mass ratio of larger primary)
    mu2 : float
        μ (mass ratio of smaller primary, alias for mu)

    Notes
    -----
    In the rotating frame:
    - The larger primary (m1) is at position (-μ, 0, 0)
    - The smaller primary (m2) is at position (1-μ, 0, 0)
    - The barycenter is at the origin
    """

    name: str
    mu: float
    distance: Optional[float] = None  # km
    period: Optional[float] = None    # seconds

    @property
    def mu1(self) -> float:
        """Mass ratio of larger primary."""
        return 1.0 - self.mu

    @property
    def mu2(self) -> float:
        """Mass ratio of smaller primary (alias for mu)."""
        return self.mu

    @property
    def primary1_position(self) -> np.ndarray:
        """Position of larger primary in rotating frame."""
        return np.array([-self.mu, 0.0, 0.0])

    @property
    def primary2_position(self) -> np.ndarray:
        """Position of smaller primary in rotating frame."""
        return np.array([1.0 - self.mu, 0.0, 0.0])

    @property
    def length_unit(self) -> Optional[float]:
        """Length unit in km (distance between primaries)."""
        return self.distance

    @property
    def time_unit(self) -> Optional[float]:
        """Time unit in seconds (period / 2π)."""
        if self.period is not None:
            return self.period / TWO_PI
        return None

    @property
    def velocity_unit(self) -> Optional[float]:
        """Velocity unit in km/s."""
        if self.distance is not None and self.period is not None:
            return self.distance / (self.period / TWO_PI)
        return None

    def to_dimensional_length(self, normalized: float) -> Optional[float]:
        """Convert normalized length to km."""
        if self.distance is not None:
            return normalized * self.distance
        return None

    def to_dimensional_time(self, normalized: float) -> Optional[float]:
        """Convert normalized time to seconds."""
        if self.time_unit is not None:
            return normalized * self.time_unit
        return None

    def to_dimensional_velocity(self, normalized: float) -> Optional[float]:
        """Convert normalized velocity to km/s."""
        if self.velocity_unit is not None:
            return normalized * self.velocity_unit
        return None

    def to_normalized_length(self, km: float) -> Optional[float]:
        """Convert km to normalized length."""
        if self.distance is not None:
            return km / self.distance
        return None

    def to_normalized_time(self, seconds: float) -> Optional[float]:
        """Convert seconds to normalized time."""
        if self.time_unit is not None:
            return seconds / self.time_unit
        return None

    def distance_to_primary1(self, state: np.ndarray) -> float:
        """
        Calculate distance from state to larger primary.

        Parameters
        ----------
        state : ndarray
            State vector [x, y, z, ...] or position [x, y, z]

        Returns
        -------
        float
            Distance r1 to larger primary
        """
        x, y, z = state[0], state[1], state[2] if len(state) > 2 else 0.0
        return np.sqrt((x + self.mu)**2 + y**2 + z**2)

    def distance_to_primary2(self, state: np.ndarray) -> float:
        """
        Calculate distance from state to smaller primary.

        Parameters
        ----------
        state : ndarray
            State vector [x, y, z, ...] or position [x, y, z]

        Returns
        -------
        float
            Distance r2 to smaller primary
        """
        x, y, z = state[0], state[1], state[2] if len(state) > 2 else 0.0
        return np.sqrt((x - 1.0 + self.mu)**2 + y**2 + z**2)

    def __repr__(self) -> str:
        return f"System('{self.name}', μ={self.mu:.6e})"


# =============================================================================
# Pre-defined Systems
# =============================================================================

SUN_EARTH = System(
    name="Sun-Earth",
    mu=MU_SUN_EARTH,
    distance=SUN_EARTH_DISTANCE,
    period=SUN_EARTH_PERIOD,
)

EARTH_MOON = System(
    name="Earth-Moon",
    mu=MU_EARTH_MOON,
    distance=EARTH_MOON_DISTANCE,
    period=EARTH_MOON_PERIOD,
)

SUN_JUPITER = System(
    name="Sun-Jupiter",
    mu=MU_SUN_JUPITER,
    distance=778.5e6,  # km (approximate)
    period=11.86 * 365.25 * 24 * 3600,  # seconds
)

SUN_MARS = System(
    name="Sun-Mars",
    mu=MU_SUN_MARS,
    distance=227.9e6,  # km (approximate)
    period=687.0 * 24 * 3600,  # seconds
)

SUN_VENUS = System(
    name="Sun-Venus",
    mu=MU_SUN_VENUS,
    distance=108.2e6,  # km (approximate)
    period=224.7 * 24 * 3600,  # seconds
)

# Dictionary of all systems
SYSTEMS = {
    "sun-earth": SUN_EARTH,
    "earth-moon": EARTH_MOON,
    "sun-jupiter": SUN_JUPITER,
    "sun-mars": SUN_MARS,
    "sun-venus": SUN_VENUS,
}


def get_system(name: str) -> System:
    """
    Get a pre-defined system by name.

    Parameters
    ----------
    name : str
        System name (case-insensitive)

    Returns
    -------
    System
        The requested system

    Raises
    ------
    KeyError
        If system name is not found
    """
    key = name.lower().replace(" ", "-").replace("_", "-")
    if key not in SYSTEMS:
        available = ", ".join(SYSTEMS.keys())
        raise KeyError(f"Unknown system '{name}'. Available: {available}")
    return SYSTEMS[key]
