"""
HALE Orbital Mechanics Library

A Python implementation of classical orbital mechanics based on
Francis J. Hale's "Introduction to Space Flight" (Prentice Hall, 1994).

Modules
-------
constants : Physical constants (Hale Appendix B)
twobody : Two-body problem equations (Hale Chapter 2)
elements : Orbital elements conversions (Hale Chapters 3-4)
kepler : Kepler's equation solvers (Hale Chapter 4)
lambert : Lambert problem solver (Hale Chapter 5)
maneuvers : Orbital maneuvers (Hale Chapter 6)
interplanetary : Patched conic trajectories (Hale Chapters 7-8)

Example
-------
>>> from hale import constants
>>> print(f"Earth μ = {constants.MU_EARTH} km³/s²")
Earth μ = 398600.4418 km³/s²

>>> from hale.twobody import vis_viva
>>> v = vis_viva(r=6678, a=6678, mu=constants.MU_EARTH)
>>> print(f"Circular LEO velocity: {v:.3f} km/s")
Circular LEO velocity: 7.726 km/s
"""

__version__ = "0.1.0"
__author__ = "Timothy Hennessey"
__email__ = "timothyehennessey@gmail.com"

# Constants will be imported when implemented
# from .constants import MU_EARTH, MU_SUN, R_EARTH, AU

__all__ = [
    "__version__",
]
