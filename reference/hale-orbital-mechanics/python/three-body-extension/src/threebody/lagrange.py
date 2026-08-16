"""
Lagrange point calculations for the CR3BP.

The five Lagrange points (L1-L5) are equilibrium points where a spacecraft
can remain stationary relative to the two primaries.

- L1, L2, L3: Collinear points (on x-axis), always unstable
- L4, L5: Triangular points (equilateral triangle), stable if μ < 0.0385

References
----------
- Szebehely, V. "Theory of Orbits" (1967), Chapter 5
- Vallado, D. "Fundamentals of Astrodynamics" (2013), Section 3.4
"""

import numpy as np
from numpy.typing import NDArray
from typing import Tuple, List
from scipy.optimize import brentq, newton

from .constants import MU_CRITICAL_ROUTH


def lagrange_point_L1(mu: float, tol: float = 1e-12) -> NDArray[np.float64]:
    """
    Calculate L1 position (between the two primaries).

    L1 is located between the two primaries, closer to the smaller one.
    For Sun-Earth, L1 is about 1.5 million km sunward of Earth (SOHO location).

    Parameters
    ----------
    mu : float
        Mass ratio μ = m₂/(m₁ + m₂)
    tol : float
        Convergence tolerance

    Returns
    -------
    ndarray
        Position [x, y, z] in rotating frame

    Notes
    -----
    L1 is found by solving the quintic equation for the x-coordinate.
    At equilibrium on x-axis: x - (1-μ)(x+μ)/|x+μ|³ - μ(x-1+μ)/|x-1+μ|³ = 0
    For L1 (between primaries): x + mu > 0 and x - 1 + mu < 0
    """
    # L1 is between the primaries, closer to the smaller one
    # Use Hill sphere approximation for initial guess
    gamma = (mu / 3) ** (1/3)
    x_guess = 1 - mu - gamma

    def f(x):
        # For L1: x is between -mu and (1-mu)
        # So (x + mu) > 0 and (x - 1 + mu) < 0
        # Equilibrium: x - (1-μ)/(x+μ)² + μ/(1-μ-x)² = 0
        r1 = x + mu           # positive for L1
        r2 = 1 - mu - x       # positive for L1 (distance to primary 2)
        return x - (1 - mu) / r1**2 + mu / r2**2

    def fprime(x):
        r1 = x + mu
        r2 = 1 - mu - x
        return 1 + 2*(1 - mu) / r1**3 + 2*mu / r2**3

    # Solve using Newton's method with derivative
    try:
        x_L1 = newton(f, x_guess, fprime=fprime, tol=tol, maxiter=100)
    except RuntimeError:
        # Fall back to Brent's method with proper bracket
        x_L1 = brentq(f, -mu + 0.01, 1 - mu - 0.001, xtol=tol)

    return np.array([x_L1, 0.0, 0.0])


def lagrange_point_L2(mu: float, tol: float = 1e-12) -> NDArray[np.float64]:
    """
    Calculate L2 position (beyond the smaller primary).

    L2 is located beyond the smaller primary, away from the larger one.
    For Sun-Earth, L2 is about 1.5 million km from Earth (JWST location).

    Parameters
    ----------
    mu : float
        Mass ratio
    tol : float
        Convergence tolerance

    Returns
    -------
    ndarray
        Position [x, y, z] in rotating frame
    """
    # L2 is beyond the smaller primary
    gamma = (mu / 3) ** (1/3)
    x_guess = 1 - mu + gamma

    def f(x):
        # For L2: x > (1-mu), so both (x+mu) > 0 and (x-1+mu) > 0
        r1 = x + mu
        r2 = x - 1 + mu
        return x - (1 - mu) / r1**2 - mu / r2**2

    def fprime(x):
        r1 = x + mu
        r2 = x - 1 + mu
        return 1 + 2*(1 - mu) / r1**3 + 2*mu / r2**3

    try:
        x_L2 = newton(f, x_guess, fprime=fprime, tol=tol, maxiter=100)
    except RuntimeError:
        x_L2 = brentq(f, 1 - mu + 0.001, 2.0, xtol=tol)

    return np.array([x_L2, 0.0, 0.0])


def lagrange_point_L3(mu: float, tol: float = 1e-12) -> NDArray[np.float64]:
    """
    Calculate L3 position (opposite side from smaller primary).

    L3 is located on the opposite side of the larger primary from the
    smaller primary. It's always much further from the barycenter.

    Parameters
    ----------
    mu : float
        Mass ratio
    tol : float
        Convergence tolerance

    Returns
    -------
    ndarray
        Position [x, y, z] in rotating frame
    """
    # L3 is on the opposite side, approximately at x ≈ -1
    x_guess = -1 - 5 * mu / 12

    def f(x):
        # For L3: x < -mu, so (x+mu) < 0 and (x-1+mu) < 0
        r1 = -(x + mu)        # positive
        r2 = -(x - 1 + mu)    # positive
        return x + (1 - mu) / r1**2 + mu / r2**2

    def fprime(x):
        r1 = -(x + mu)
        r2 = -(x - 1 + mu)
        return 1 + 2*(1 - mu) / r1**3 + 2*mu / r2**3

    try:
        x_L3 = newton(f, x_guess, fprime=fprime, tol=tol, maxiter=100)
    except RuntimeError:
        x_L3 = brentq(f, -2.0, -mu - 0.01, xtol=tol)

    return np.array([x_L3, 0.0, 0.0])


def lagrange_point_L4(mu: float) -> NDArray[np.float64]:
    """
    Calculate L4 position (leading triangular point).

    L4 forms an equilateral triangle with the two primaries, located
    60° ahead of the smaller primary in its orbit.

    Parameters
    ----------
    mu : float
        Mass ratio

    Returns
    -------
    ndarray
        Position [x, y, z] in rotating frame

    Notes
    -----
    L4 is analytically known: x = 0.5 - μ, y = √3/2
    """
    x = 0.5 - mu
    y = np.sqrt(3) / 2
    return np.array([x, y, 0.0])


def lagrange_point_L5(mu: float) -> NDArray[np.float64]:
    """
    Calculate L5 position (trailing triangular point).

    L5 forms an equilateral triangle with the two primaries, located
    60° behind the smaller primary in its orbit.

    Parameters
    ----------
    mu : float
        Mass ratio

    Returns
    -------
    ndarray
        Position [x, y, z] in rotating frame

    Notes
    -----
    L5 is analytically known: x = 0.5 - μ, y = -√3/2
    """
    x = 0.5 - mu
    y = -np.sqrt(3) / 2
    return np.array([x, y, 0.0])


def lagrange_points(mu: float, tol: float = 1e-12) -> List[NDArray[np.float64]]:
    """
    Calculate all five Lagrange points.

    Parameters
    ----------
    mu : float
        Mass ratio
    tol : float
        Convergence tolerance for collinear points

    Returns
    -------
    list
        [L1, L2, L3, L4, L5] positions in rotating frame

    Example
    -------
    >>> from threebody.lagrange import lagrange_points
    >>> L_points = lagrange_points(0.01215)  # Earth-Moon
    >>> print(f"L1: {L_points[0]}")
    >>> print(f"L2: {L_points[1]}")
    """
    return [
        lagrange_point_L1(mu, tol),
        lagrange_point_L2(mu, tol),
        lagrange_point_L3(mu, tol),
        lagrange_point_L4(mu),
        lagrange_point_L5(mu),
    ]


def lagrange_point_jacobi_constants(mu: float) -> List[float]:
    """
    Calculate Jacobi constants at all Lagrange points.

    The Jacobi constant at each point determines the energy level
    at which that point becomes accessible.

    Parameters
    ----------
    mu : float
        Mass ratio

    Returns
    -------
    list
        [C_L1, C_L2, C_L3, C_L4, C_L5] Jacobi constants

    Notes
    -----
    The ordering is always: C_L1 > C_L2 > C_L3 > C_L4 = C_L5
    (for typical planetary mass ratios)
    """
    from .cr3bp import jacobi_at_lagrange_point

    L_points = lagrange_points(mu)
    return [jacobi_at_lagrange_point(L, mu) for L in L_points]


def is_L4_L5_stable(mu: float) -> bool:
    """
    Check if L4 and L5 are linearly stable.

    According to Routh's criterion, L4 and L5 are stable only when
    μ < μ_critical ≈ 0.0385.

    Parameters
    ----------
    mu : float
        Mass ratio

    Returns
    -------
    bool
        True if L4/L5 are linearly stable
    """
    return mu < MU_CRITICAL_ROUTH


def linearized_dynamics_at_lagrange(
    L_position: NDArray[np.float64],
    mu: float
) -> Tuple[NDArray[np.float64], NDArray[np.float64]]:
    """
    Compute linearized dynamics matrix at a Lagrange point.

    The state-space form is: δẋ = A δx, where δx is deviation from L-point.

    Parameters
    ----------
    L_position : ndarray
        Lagrange point position [x, y, z]
    mu : float
        Mass ratio

    Returns
    -------
    tuple
        (A, eigenvalues) where A is 6x6 Jacobian matrix

    Notes
    -----
    For collinear points (L1, L2, L3):
    - Eigenvalues include real positive/negative pair → unstable
    - Complex conjugate pairs → oscillatory motion

    For triangular points (L4, L5) when stable:
    - All eigenvalues are purely imaginary → stable oscillation
    """
    x, y, z = L_position[0], L_position[1], 0.0

    # Compute distances to primaries
    r1 = np.sqrt((x + mu)**2 + y**2 + z**2)
    r2 = np.sqrt((x - 1 + mu)**2 + y**2 + z**2)

    r1_3 = r1**3
    r2_3 = r2**3
    r1_5 = r1**5
    r2_5 = r2**5

    mu1 = 1 - mu
    mu2 = mu

    # Second partial derivatives of Omega
    Uxx = 1 - mu1/r1_3 - mu2/r2_3 + 3*mu1*(x+mu)**2/r1_5 + 3*mu2*(x-1+mu)**2/r2_5
    Uyy = 1 - mu1/r1_3 - mu2/r2_3 + 3*mu1*y**2/r1_5 + 3*mu2*y**2/r2_5
    Uzz = -mu1/r1_3 - mu2/r2_3 + 3*mu1*z**2/r1_5 + 3*mu2*z**2/r2_5
    Uxy = 3*mu1*(x+mu)*y/r1_5 + 3*mu2*(x-1+mu)*y/r2_5
    Uxz = 3*mu1*(x+mu)*z/r1_5 + 3*mu2*(x-1+mu)*z/r2_5
    Uyz = 3*mu1*y*z/r1_5 + 3*mu2*y*z/r2_5

    # Jacobian matrix (linearized equations of motion)
    A = np.array([
        [0, 0, 0, 1, 0, 0],
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 0, 1],
        [Uxx, Uxy, Uxz, 0, 2, 0],
        [Uxy, Uyy, Uyz, -2, 0, 0],
        [Uxz, Uyz, Uzz, 0, 0, 0]
    ])

    eigenvalues = np.linalg.eigvals(A)

    return A, eigenvalues


def classify_lagrange_point(eigenvalues: NDArray[np.complex128]) -> str:
    """
    Classify stability type based on eigenvalues.

    Parameters
    ----------
    eigenvalues : ndarray
        Eigenvalues of linearized dynamics

    Returns
    -------
    str
        Classification: "stable", "unstable-saddle", "unstable-spiral"
    """
    real_parts = np.real(eigenvalues)
    has_positive_real = np.any(real_parts > 1e-10)
    has_negative_real = np.any(real_parts < -1e-10)
    all_imaginary = np.all(np.abs(real_parts) < 1e-10)

    if all_imaginary:
        return "stable"
    elif has_positive_real and has_negative_real:
        return "unstable-saddle"
    else:
        return "unstable-spiral"


def approximate_L1_position(mu: float) -> float:
    """
    Approximate L1 x-coordinate using series expansion.

    Good for small μ (planetary systems).

    Parameters
    ----------
    mu : float
        Mass ratio

    Returns
    -------
    float
        Approximate x-coordinate of L1
    """
    gamma = (mu / 3) ** (1/3)
    return 1 - mu - gamma + gamma**2/3 - gamma**3/9


def approximate_L2_position(mu: float) -> float:
    """
    Approximate L2 x-coordinate using series expansion.

    Parameters
    ----------
    mu : float
        Mass ratio

    Returns
    -------
    float
        Approximate x-coordinate of L2
    """
    gamma = (mu / 3) ** (1/3)
    return 1 - mu + gamma + gamma**2/3 - gamma**3/9


def distance_from_primary2_to_L1(mu: float) -> float:
    """
    Distance from smaller primary to L1.

    Parameters
    ----------
    mu : float
        Mass ratio

    Returns
    -------
    float
        Distance (normalized units)
    """
    L1 = lagrange_point_L1(mu)
    return abs(L1[0] - (1 - mu))


def distance_from_primary2_to_L2(mu: float) -> float:
    """
    Distance from smaller primary to L2.

    Parameters
    ----------
    mu : float
        Mass ratio

    Returns
    -------
    float
        Distance (normalized units)
    """
    L2 = lagrange_point_L2(mu)
    return abs(L2[0] - (1 - mu))
