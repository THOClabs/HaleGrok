"""
Circular Restricted Three-Body Problem (CR3BP) equations.

The CR3BP models the motion of a massless particle (spacecraft) in the
gravitational field of two massive bodies (primaries) that orbit their
common barycenter in circular orbits.

The equations are expressed in a rotating reference frame where:
- Origin: Barycenter of the two primaries
- X-axis: Points from m1 to m2
- Z-axis: Along angular momentum vector
- Y-axis: Completes right-handed system

In normalized units:
- Distance between primaries = 1
- Angular velocity of rotating frame = 1
- G(m1 + m2) = 1

References
----------
- Szebehely, V. "Theory of Orbits" (1967), Chapter 1
- Koon, W.S. et al. "Dynamical Systems, the Three-Body Problem and
  Space Mission Design" (2011), Chapter 2
"""

import numpy as np
from numpy.typing import NDArray
from typing import Tuple, Union


def pseudo_potential(x: float, y: float, z: float, mu: float) -> float:
    """
    Calculate the pseudo-potential (effective potential) in the rotating frame.

    The pseudo-potential Ω combines gravitational and centrifugal effects:
        Ω = (x² + y²)/2 + (1-μ)/r₁ + μ/r₂

    Parameters
    ----------
    x, y, z : float
        Position in rotating frame (normalized units)
    mu : float
        Mass ratio μ = m₂/(m₁ + m₂)

    Returns
    -------
    float
        Pseudo-potential value

    Notes
    -----
    The pseudo-potential is also called the effective potential or
    the modified potential. It includes the centrifugal potential
    due to the rotating reference frame.
    """
    # Distances to primaries
    r1 = np.sqrt((x + mu)**2 + y**2 + z**2)
    r2 = np.sqrt((x - 1 + mu)**2 + y**2 + z**2)

    # Centrifugal + gravitational terms
    omega = 0.5 * (x**2 + y**2) + (1 - mu) / r1 + mu / r2

    return omega


def pseudo_potential_derivatives(
    x: float, y: float, z: float, mu: float
) -> Tuple[float, float, float]:
    """
    Calculate partial derivatives of pseudo-potential.

    Parameters
    ----------
    x, y, z : float
        Position in rotating frame (normalized units)
    mu : float
        Mass ratio

    Returns
    -------
    tuple
        (∂Ω/∂x, ∂Ω/∂y, ∂Ω/∂z)
    """
    r1 = np.sqrt((x + mu)**2 + y**2 + z**2)
    r2 = np.sqrt((x - 1 + mu)**2 + y**2 + z**2)

    r1_cubed = r1**3
    r2_cubed = r2**3

    omega_x = x - (1 - mu) * (x + mu) / r1_cubed - mu * (x - 1 + mu) / r2_cubed
    omega_y = y - (1 - mu) * y / r1_cubed - mu * y / r2_cubed
    omega_z = -(1 - mu) * z / r1_cubed - mu * z / r2_cubed

    return omega_x, omega_y, omega_z


def equations_of_motion(
    t: float,
    state: NDArray[np.float64],
    mu: float
) -> NDArray[np.float64]:
    """
    Equations of motion for the CR3BP in the rotating frame.

    The equations are:
        ẍ - 2ẏ = ∂Ω/∂x
        ÿ + 2ẋ = ∂Ω/∂y
        z̈ = ∂Ω/∂z

    Parameters
    ----------
    t : float
        Time (not used, but required for integrator compatibility)
    state : ndarray
        State vector [x, y, z, vx, vy, vz]
    mu : float
        Mass ratio

    Returns
    -------
    ndarray
        State derivative [vx, vy, vz, ax, ay, az]

    Example
    -------
    >>> from threebody.cr3bp import equations_of_motion
    >>> state = np.array([0.5, 0.0, 0.0, 0.0, 0.5, 0.0])
    >>> mu = 0.01215  # Earth-Moon
    >>> deriv = equations_of_motion(0, state, mu)
    """
    x, y, z, vx, vy, vz = state

    # Partial derivatives of pseudo-potential
    omega_x, omega_y, omega_z = pseudo_potential_derivatives(x, y, z, mu)

    # Accelerations (include Coriolis terms: -2ẏ for x, +2ẋ for y)
    ax = 2 * vy + omega_x
    ay = -2 * vx + omega_y
    az = omega_z

    return np.array([vx, vy, vz, ax, ay, az])


def equations_of_motion_with_stm(
    t: float,
    state: NDArray[np.float64],
    mu: float
) -> NDArray[np.float64]:
    """
    Equations of motion including State Transition Matrix (STM) propagation.

    The STM Φ satisfies: dΦ/dt = A(t) × Φ, where A is the Jacobian of
    the equations of motion.

    Parameters
    ----------
    t : float
        Time
    state : ndarray
        Augmented state vector [x, y, z, vx, vy, vz, Φ₁₁, Φ₁₂, ..., Φ₆₆]
        Length: 6 + 36 = 42
    mu : float
        Mass ratio

    Returns
    -------
    ndarray
        Derivative of augmented state (length 42)
    """
    # Extract position and velocity
    x, y, z, vx, vy, vz = state[:6]

    # Extract STM (6x6 matrix stored as 36 elements)
    phi = state[6:].reshape((6, 6))

    # Compute distances
    r1 = np.sqrt((x + mu)**2 + y**2 + z**2)
    r2 = np.sqrt((x - 1 + mu)**2 + y**2 + z**2)
    r1_3 = r1**3
    r2_3 = r2**3
    r1_5 = r1**5
    r2_5 = r2**5

    # Second partial derivatives of Omega (Uxx, Uxy, etc.)
    mu1 = 1 - mu
    mu2 = mu

    Uxx = 1 - mu1/r1_3 - mu2/r2_3 + 3*mu1*(x+mu)**2/r1_5 + 3*mu2*(x-1+mu)**2/r2_5
    Uyy = 1 - mu1/r1_3 - mu2/r2_3 + 3*mu1*y**2/r1_5 + 3*mu2*y**2/r2_5
    Uzz = -mu1/r1_3 - mu2/r2_3 + 3*mu1*z**2/r1_5 + 3*mu2*z**2/r2_5
    Uxy = 3*mu1*(x+mu)*y/r1_5 + 3*mu2*(x-1+mu)*y/r2_5
    Uxz = 3*mu1*(x+mu)*z/r1_5 + 3*mu2*(x-1+mu)*z/r2_5
    Uyz = 3*mu1*y*z/r1_5 + 3*mu2*y*z/r2_5

    # Jacobian matrix A
    A = np.array([
        [0, 0, 0, 1, 0, 0],
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 0, 0, 1],
        [Uxx, Uxy, Uxz, 0, 2, 0],
        [Uxy, Uyy, Uyz, -2, 0, 0],
        [Uxz, Uyz, Uzz, 0, 0, 0]
    ])

    # State derivatives
    omega_x, omega_y, omega_z = pseudo_potential_derivatives(x, y, z, mu)
    state_dot = np.array([vx, vy, vz, 2*vy + omega_x, -2*vx + omega_y, omega_z])

    # STM derivative: dΦ/dt = A × Φ
    phi_dot = A @ phi

    return np.concatenate([state_dot, phi_dot.flatten()])


def jacobi_constant(state: NDArray[np.float64], mu: float) -> float:
    """
    Calculate the Jacobi constant (integral of motion).

    The Jacobi constant C is conserved in the CR3BP:
        C = 2Ω - v²

    where v² = vx² + vy² + vz² is the velocity squared.

    Parameters
    ----------
    state : ndarray
        State vector [x, y, z, vx, vy, vz]
    mu : float
        Mass ratio

    Returns
    -------
    float
        Jacobi constant

    Notes
    -----
    - Higher Jacobi constant = lower energy
    - C determines the zero-velocity surfaces (regions spacecraft cannot reach)
    - For libration point orbits, C is near the value at that point
    """
    x, y, z, vx, vy, vz = state

    omega = pseudo_potential(x, y, z, mu)
    v_squared = vx**2 + vy**2 + vz**2

    return 2 * omega - v_squared


def effective_potential(
    x: NDArray[np.float64],
    y: NDArray[np.float64],
    mu: float,
    z: float = 0.0
) -> NDArray[np.float64]:
    """
    Calculate effective potential on a grid (for plotting).

    Parameters
    ----------
    x, y : ndarray
        2D grid of x and y values
    mu : float
        Mass ratio
    z : float
        Z coordinate (default 0 for planar)

    Returns
    -------
    ndarray
        Effective potential values on grid
    """
    r1 = np.sqrt((x + mu)**2 + y**2 + z**2)
    r2 = np.sqrt((x - 1 + mu)**2 + y**2 + z**2)

    omega = 0.5 * (x**2 + y**2) + (1 - mu) / r1 + mu / r2

    return omega


def jacobi_at_lagrange_point(L_position: NDArray[np.float64], mu: float) -> float:
    """
    Calculate Jacobi constant at a Lagrange point.

    At Lagrange points, velocity is zero, so C = 2Ω.

    Parameters
    ----------
    L_position : ndarray
        Position of Lagrange point [x, y, z]
    mu : float
        Mass ratio

    Returns
    -------
    float
        Jacobi constant at the Lagrange point
    """
    x, y, z = L_position[0], L_position[1], 0.0
    if len(L_position) > 2:
        z = L_position[2]

    return 2 * pseudo_potential(x, y, z, mu)


def zero_velocity_curve(
    C: float,
    mu: float,
    x_range: Tuple[float, float] = (-1.5, 1.5),
    y_range: Tuple[float, float] = (-1.5, 1.5),
    n_points: int = 500
) -> Tuple[NDArray, NDArray, NDArray]:
    """
    Compute zero-velocity curve data for a given Jacobi constant.

    The zero-velocity surface is where C = 2Ω (v = 0).
    In the x-y plane, these are curves that bound accessible regions.

    Parameters
    ----------
    C : float
        Jacobi constant
    mu : float
        Mass ratio
    x_range : tuple
        (x_min, x_max) for grid
    y_range : tuple
        (y_min, y_max) for grid
    n_points : int
        Number of grid points in each dimension

    Returns
    -------
    tuple
        (X, Y, Z) where Z = 2Ω - C (zero contour is the ZVC)
    """
    x = np.linspace(x_range[0], x_range[1], n_points)
    y = np.linspace(y_range[0], y_range[1], n_points)
    X, Y = np.meshgrid(x, y)

    omega = effective_potential(X, Y, mu)
    Z = 2 * omega - C

    return X, Y, Z


def state_in_rotating_frame(
    r_inertial: NDArray[np.float64],
    v_inertial: NDArray[np.float64],
    theta: float
) -> Tuple[NDArray[np.float64], NDArray[np.float64]]:
    """
    Transform state from inertial to rotating frame.

    Parameters
    ----------
    r_inertial : ndarray
        Position in inertial frame [x, y, z]
    v_inertial : ndarray
        Velocity in inertial frame [vx, vy, vz]
    theta : float
        Rotation angle (normalized time in CR3BP)

    Returns
    -------
    tuple
        (r_rotating, v_rotating) state in rotating frame
    """
    cos_t = np.cos(theta)
    sin_t = np.sin(theta)

    # Rotation matrix (inertial to rotating)
    R = np.array([
        [cos_t, sin_t, 0],
        [-sin_t, cos_t, 0],
        [0, 0, 1]
    ])

    # Position in rotating frame
    r_rot = R @ r_inertial

    # Velocity transformation includes frame rotation
    # v_rot = R @ v_inertial - ω × r_rot
    # In normalized units, ω = 1 along z-axis
    omega_cross_r = np.array([-r_rot[1], r_rot[0], 0])
    v_rot = R @ v_inertial - omega_cross_r

    return r_rot, v_rot


def state_in_inertial_frame(
    r_rotating: NDArray[np.float64],
    v_rotating: NDArray[np.float64],
    theta: float
) -> Tuple[NDArray[np.float64], NDArray[np.float64]]:
    """
    Transform state from rotating to inertial frame.

    Parameters
    ----------
    r_rotating : ndarray
        Position in rotating frame [x, y, z]
    v_rotating : ndarray
        Velocity in rotating frame [vx, vy, vz]
    theta : float
        Rotation angle (normalized time)

    Returns
    -------
    tuple
        (r_inertial, v_inertial) state in inertial frame
    """
    cos_t = np.cos(theta)
    sin_t = np.sin(theta)

    # Rotation matrix (rotating to inertial)
    R = np.array([
        [cos_t, -sin_t, 0],
        [sin_t, cos_t, 0],
        [0, 0, 1]
    ])

    # Position in inertial frame
    r_iner = R @ r_rotating

    # Velocity transformation
    omega_cross_r = np.array([-r_rotating[1], r_rotating[0], 0])
    v_iner = R @ (v_rotating + omega_cross_r)

    return r_iner, v_iner
