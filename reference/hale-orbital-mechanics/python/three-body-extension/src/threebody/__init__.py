"""
Three-Body Problem Extension for HALE Orbital Mechanics

This module implements the Circular Restricted Three-Body Problem (CR3BP)
and related tools for mission design in multi-body gravitational environments.

Modules
-------
constants : System parameters and mass ratios
cr3bp : Core CR3BP equations of motion
lagrange : Lagrange point calculations (L1-L5)
integrators : Numerical integration methods
periodic : Periodic orbit computation (Halo, Lyapunov, Lissajous)
stability : Stability analysis and invariant manifolds
systems : Pre-defined gravitational systems

Example
-------
>>> from threebody import systems, cr3bp
>>> system = systems.SUN_EARTH
>>> L2 = system.lagrange_points()[1]  # L2 position
>>> print(f"Sun-Earth L2 at x = {L2[0]:.6f} (normalized)")
"""

__version__ = "0.1.0"

from .constants import (
    MU_SUN_EARTH,
    MU_EARTH_MOON,
    MU_SUN_JUPITER,
)
from .systems import System, SUN_EARTH, EARTH_MOON, SUN_JUPITER
from .cr3bp import (
    equations_of_motion,
    pseudo_potential,
    jacobi_constant,
    effective_potential,
)
from .lagrange import (
    lagrange_points,
    lagrange_point_L1,
    lagrange_point_L2,
    lagrange_point_L3,
    lagrange_point_L4,
    lagrange_point_L5,
)
from .integrators import (
    propagate,
    rk4_step,
    rk45_step,
)

__all__ = [
    "__version__",
    # Constants
    "MU_SUN_EARTH",
    "MU_EARTH_MOON",
    "MU_SUN_JUPITER",
    # Systems
    "System",
    "SUN_EARTH",
    "EARTH_MOON",
    "SUN_JUPITER",
    # CR3BP
    "equations_of_motion",
    "pseudo_potential",
    "jacobi_constant",
    "effective_potential",
    # Lagrange
    "lagrange_points",
    "lagrange_point_L1",
    "lagrange_point_L2",
    "lagrange_point_L3",
    "lagrange_point_L4",
    "lagrange_point_L5",
    # Integrators
    "propagate",
    "rk4_step",
    "rk45_step",
]
