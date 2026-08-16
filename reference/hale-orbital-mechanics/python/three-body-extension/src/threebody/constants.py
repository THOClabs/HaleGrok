"""
Physical constants and mass ratios for three-body systems.

All values use normalized units where:
- Length unit (LU) = distance between primaries
- Time unit (TU) = chosen so that orbital period = 2*pi
- Mass unit (MU) = total mass of primaries

The key parameter is mu (μ), the mass ratio:
    μ = m2 / (m1 + m2)

where m2 is the smaller primary (e.g., Earth in Sun-Earth system).

References
----------
- JPL Solar System Dynamics: https://ssd.jpl.nasa.gov/
- Szebehely, V. "Theory of Orbits" (1967)
"""

import numpy as np

# =============================================================================
# Mass Ratios (dimensionless)
# =============================================================================

# Sun-Earth system
# m_Earth / (m_Sun + m_Earth)
MU_SUN_EARTH = 3.003480593e-6

# Earth-Moon system
# m_Moon / (m_Earth + m_Moon)
MU_EARTH_MOON = 0.01215058560962404

# Sun-Jupiter system
# m_Jupiter / (m_Sun + m_Jupiter)
MU_SUN_JUPITER = 9.537e-4

# Sun-Mars system
MU_SUN_MARS = 3.227e-7

# Sun-Venus system
MU_SUN_VENUS = 2.448e-6

# =============================================================================
# Dimensional Constants (for converting to physical units)
# =============================================================================

# Sun-Earth system
SUN_EARTH_DISTANCE = 149597870.7  # km (1 AU)
SUN_EARTH_PERIOD = 365.25 * 24 * 3600  # seconds (1 year)
SUN_EARTH_MU_DIM = 1.32712440018e11  # km³/s² (Sun's gravitational parameter)

# Earth-Moon system
EARTH_MOON_DISTANCE = 384400.0  # km
EARTH_MOON_PERIOD = 27.321661 * 24 * 3600  # seconds
EARTH_MOON_MU_DIM = 398600.4418  # km³/s² (Earth's gravitational parameter)

# =============================================================================
# Critical Mass Ratio
# =============================================================================

# Routh's critical mass ratio for L4/L5 stability
# L4 and L5 are stable only if μ < μ_critical
MU_CRITICAL_ROUTH = (1 - np.sqrt(69) / 9) / 2  # ≈ 0.0385209

# =============================================================================
# Useful Mathematical Constants
# =============================================================================

PI = np.pi
TWO_PI = 2 * np.pi
SQRT2 = np.sqrt(2)
SQRT3 = np.sqrt(3)
