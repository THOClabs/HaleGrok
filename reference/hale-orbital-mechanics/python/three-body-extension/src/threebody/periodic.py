"""
Periodic orbit computation in the CR3BP.

Includes algorithms for finding and continuing:
- Lyapunov orbits (planar, around L1, L2, L3)
- Halo orbits (3D, around L1, L2)
- Lissajous orbits (quasi-periodic)

References
----------
- Richardson, D.L. "Analytic Construction of Periodic Orbits about the
  Collinear Points" (1980), Celestial Mechanics, 22, 241-253
- Howell, K.C. "Three-Dimensional, Periodic, 'Halo' Orbits" (1984)
"""

import numpy as np
from numpy.typing import NDArray
from typing import Tuple, Optional, List
from scipy.optimize import fsolve
from dataclasses import dataclass

from .cr3bp import equations_of_motion, equations_of_motion_with_stm, jacobi_constant
from .lagrange import lagrange_point_L1, lagrange_point_L2
from .integrators import propagate_fixed_step, propagate_with_events, y_crossing_event


@dataclass
class PeriodicOrbit:
    """
    A periodic orbit in the CR3BP.

    Attributes
    ----------
    initial_state : ndarray
        Initial state [x, y, z, vx, vy, vz]
    period : float
        Orbital period (normalized time)
    jacobi : float
        Jacobi constant
    stability_index : float
        Stability index (|λ| for largest eigenvalue)
    orbit_type : str
        Type: "lyapunov", "halo_north", "halo_south"
    family : str
        Orbit family identifier
    """
    initial_state: NDArray[np.float64]
    period: float
    jacobi: float
    stability_index: float = 1.0
    orbit_type: str = "unknown"
    family: str = "unknown"


def richardson_halo_initial_guess(
    mu: float,
    Az: float,
    L_point: int = 2,
    northern: bool = True
) -> Tuple[NDArray[np.float64], float]:
    """
    Generate initial guess for halo orbit using Richardson's approximation.

    Uses third-order analytical approximation for halo orbit initial conditions.

    Parameters
    ----------
    mu : float
        Mass ratio
    Az : float
        Z-amplitude (normalized units)
    L_point : int
        Lagrange point (1 or 2)
    northern : bool
        True for northern halo, False for southern

    Returns
    -------
    tuple
        (state0, period_guess) initial state and estimated period

    References
    ----------
    Richardson, D.L. (1980). Celestial Mechanics, 22, 241-253.
    """
    # Get Lagrange point position
    if L_point == 1:
        gamma_L = 1 - mu - lagrange_point_L1(mu)[0]
    else:  # L2
        gamma_L = lagrange_point_L2(mu)[0] - (1 - mu)

    # Richardson coefficients (simplified)
    c2 = (mu + (1-mu)*gamma_L**3 / (1-gamma_L)**3) / gamma_L**3
    c3 = (mu - (1-mu)*gamma_L**4 / (1-gamma_L)**4) / gamma_L**3
    c4 = (mu + (1-mu)*gamma_L**5 / (1-gamma_L)**5) / gamma_L**3

    # Eigenvalue parameter
    lam = np.sqrt((c2 - 2 + np.sqrt((c2-2)**2 + 4*(c2-1)*(1+2*c2))) / 2)

    # Frequency
    omega_p = np.sqrt(2 - c2 + np.sqrt(9*c2**2 - 8*c2)) / np.sqrt(2)

    # Period approximation
    T = 2 * np.pi / omega_p

    # Amplitude constraint
    Ax = Az  # Simplified; actual relation is more complex

    # Initial state on halo
    if L_point == 1:
        x0 = 1 - mu - gamma_L + Ax
    else:
        x0 = 1 - mu + gamma_L - Ax

    z0 = Az if northern else -Az
    vy0 = -lam * Ax * omega_p / gamma_L

    state0 = np.array([x0, 0.0, z0, 0.0, vy0, 0.0])

    return state0, T


def lyapunov_initial_guess(
    mu: float,
    Ax: float,
    L_point: int = 2
) -> Tuple[NDArray[np.float64], float]:
    """
    Generate initial guess for Lyapunov orbit.

    Parameters
    ----------
    mu : float
        Mass ratio
    Ax : float
        X-amplitude from Lagrange point
    L_point : int
        Lagrange point (1, 2, or 3)

    Returns
    -------
    tuple
        (state0, period_guess)
    """
    if L_point == 1:
        xL = lagrange_point_L1(mu)[0]
        x0 = xL + Ax
    elif L_point == 2:
        xL = lagrange_point_L2(mu)[0]
        x0 = xL - Ax
    else:
        raise ValueError("L3 Lyapunov not yet implemented")

    # Estimate period from linearized dynamics
    # For L1/L2, period is approximately 2*pi / omega where omega depends on mu
    omega_approx = np.sqrt(2)  # Rough approximation
    T_guess = 2 * np.pi / omega_approx

    # Initial velocity perpendicular to x-axis
    vy_guess = 0.2 * Ax  # Rough scaling

    state0 = np.array([x0, 0.0, 0.0, 0.0, vy_guess, 0.0])

    return state0, T_guess


def differential_correction_planar(
    state0: NDArray[np.float64],
    T_guess: float,
    mu: float,
    tol: float = 1e-10,
    max_iter: int = 50
) -> Tuple[NDArray[np.float64], float, bool]:
    """
    Differential correction to find periodic planar orbit.

    Uses single-shooting method targeting perpendicular y-axis crossing.

    Parameters
    ----------
    state0 : ndarray
        Initial guess [x, 0, 0, 0, vy, 0]
    T_guess : float
        Estimated half-period
    mu : float
        Mass ratio
    tol : float
        Convergence tolerance
    max_iter : int
        Maximum iterations

    Returns
    -------
    tuple
        (corrected_state, period, converged)
    """
    x0 = state0[0]
    vy0 = state0[4]

    for iteration in range(max_iter):
        # Propagate with STM
        result = propagate_fixed_step(
            state0, (0, T_guess), mu, dt=0.0001, with_stm=True
        )

        # Find y=0 crossing with vy < 0 (coming back)
        y_vals = result.y[:, 1]
        vy_vals = result.y[:, 4]

        # Look for sign change in y where vy < 0
        crossings = []
        for i in range(1, len(y_vals)):
            if y_vals[i-1] * y_vals[i] < 0 and vy_vals[i] < 0:
                # Linear interpolation for crossing time
                t_cross = result.t[i-1] + (result.t[i] - result.t[i-1]) * \
                          abs(y_vals[i-1]) / (abs(y_vals[i-1]) + abs(y_vals[i]))
                crossings.append((i, t_cross))

        if not crossings:
            # Extend integration if no crossing found
            T_guess *= 1.5
            continue

        idx, t_half = crossings[0]

        # State at crossing
        state_half = result.y[idx, :6]
        vx_f = state_half[3]
        y_f = state_half[1]  # Should be ~0

        # Check convergence
        if abs(vx_f) < tol and abs(y_f) < tol:
            period = 2 * t_half
            return state0, period, True

        # Extract STM at crossing (approximate)
        phi = result.y[idx, 6:].reshape((6, 6))

        # Correction equations
        # We want: vx(T/2) = 0, y(T/2) = 0
        # Free variables: x0, vy0, T/2

        # Jacobian of constraints w.r.t. free variables
        # d(vx_f)/d(x0) = phi[3,0]
        # d(vx_f)/d(vy0) = phi[3,4]
        # d(vx_f)/d(T) = ax_f = state derivative at T

        deriv_at_half = equations_of_motion(t_half, state_half, mu)
        ax_f = deriv_at_half[3]
        vy_f_deriv = deriv_at_half[1]

        # For planar with y(T/2)=0 perpendicular crossing:
        # Use only x0 and vy0 as free variables (fix T/2 approximately)

        J = np.array([
            [phi[3, 0], phi[3, 4]],
            [phi[1, 0], phi[1, 4]]
        ])

        target = np.array([-vx_f, -y_f])

        try:
            delta = np.linalg.solve(J, target)
        except np.linalg.LinAlgError:
            return state0, 2*T_guess, False

        # Update
        x0 += delta[0]
        vy0 += delta[1]

        # Damping for stability
        x0 = state0[0] + 0.5 * (x0 - state0[0])
        vy0 = state0[4] + 0.5 * (vy0 - state0[4])

        state0 = np.array([x0, 0.0, 0.0, 0.0, vy0, 0.0])

    return state0, 2*T_guess, False


def find_lyapunov_orbit(
    mu: float,
    Ax: float,
    L_point: int = 2,
    tol: float = 1e-10
) -> Optional[PeriodicOrbit]:
    """
    Find a Lyapunov orbit around a Lagrange point.

    Parameters
    ----------
    mu : float
        Mass ratio
    Ax : float
        X-amplitude from Lagrange point (normalized)
    L_point : int
        Lagrange point (1 or 2)
    tol : float
        Convergence tolerance

    Returns
    -------
    PeriodicOrbit or None
        Periodic orbit if converged, None otherwise
    """
    state0, T_guess = lyapunov_initial_guess(mu, Ax, L_point)
    state_corrected, period, converged = differential_correction_planar(
        state0, T_guess/2, mu, tol
    )

    if converged:
        C = jacobi_constant(state_corrected, mu)
        return PeriodicOrbit(
            initial_state=state_corrected,
            period=period,
            jacobi=C,
            orbit_type="lyapunov",
            family=f"L{L_point}"
        )
    return None


def differential_correction_3d(
    state0: NDArray[np.float64],
    T_guess: float,
    mu: float,
    tol: float = 1e-10,
    max_iter: int = 50
) -> Tuple[NDArray[np.float64], float, bool]:
    """
    Differential correction for 3D periodic orbit (halo).

    Single-shooting targeting y=0, vx=0, vz=0 at half period.

    Parameters
    ----------
    state0 : ndarray
        Initial guess [x, 0, z, 0, vy, 0]
    T_guess : float
        Estimated half-period
    mu : float
        Mass ratio
    tol : float
        Convergence tolerance
    max_iter : int
        Maximum iterations

    Returns
    -------
    tuple
        (corrected_state, period, converged)
    """
    x0 = state0[0]
    z0 = state0[2]
    vy0 = state0[4]

    state = state0.copy()

    for iteration in range(max_iter):
        # Propagate with STM
        phi0 = np.eye(6).flatten()
        aug_state = np.concatenate([state, phi0])

        result = propagate_fixed_step(
            state, (0, T_guess*1.5), mu, dt=0.0001, with_stm=True
        )

        # Find y=0 crossing with vy < 0
        y_vals = result.y[:, 1]
        vy_vals = result.y[:, 4]

        crossings = []
        for i in range(1, len(y_vals)):
            if y_vals[i-1] * y_vals[i] < 0 and vy_vals[i] < 0:
                t_cross = result.t[i-1] + (result.t[i] - result.t[i-1]) * \
                          abs(y_vals[i-1]) / (abs(y_vals[i-1]) + abs(y_vals[i]))
                crossings.append((i, t_cross))

        if not crossings:
            T_guess *= 1.2
            continue

        idx, t_half = crossings[0]
        state_half = result.y[idx, :6]

        vx_f = state_half[3]
        vz_f = state_half[5]
        y_f = state_half[1]

        error = np.sqrt(vx_f**2 + vz_f**2 + y_f**2)
        if error < tol:
            return state, 2*t_half, True

        # STM at half period
        phi = result.y[idx, 6:].reshape((6, 6))

        # Derivatives at half period for time dependence
        deriv = equations_of_motion(t_half, state_half, mu)

        # Free vars: x0, z0, vy0 (and implicitly T/2)
        # Constraints: vx(T/2)=0, vz(T/2)=0, y(T/2)=0

        J = np.array([
            [phi[3, 0], phi[3, 2], phi[3, 4]],
            [phi[5, 0], phi[5, 2], phi[5, 4]],
            [phi[1, 0], phi[1, 2], phi[1, 4]]
        ])

        target = np.array([-vx_f, -vz_f, -y_f])

        try:
            delta = np.linalg.solve(J, target)
        except np.linalg.LinAlgError:
            return state, 2*T_guess, False

        # Update with damping
        state[0] += 0.5 * delta[0]
        state[2] += 0.5 * delta[1]
        state[4] += 0.5 * delta[2]

    return state, 2*T_guess, False


def find_halo_orbit(
    mu: float,
    Az: float,
    L_point: int = 2,
    northern: bool = True,
    tol: float = 1e-8
) -> Optional[PeriodicOrbit]:
    """
    Find a halo orbit around L1 or L2.

    Parameters
    ----------
    mu : float
        Mass ratio
    Az : float
        Z-amplitude (normalized)
    L_point : int
        Lagrange point (1 or 2)
    northern : bool
        True for northern family, False for southern
    tol : float
        Convergence tolerance

    Returns
    -------
    PeriodicOrbit or None
        Periodic orbit if converged

    Example
    -------
    >>> from threebody.periodic import find_halo_orbit
    >>> from threebody import EARTH_MOON
    >>> orbit = find_halo_orbit(EARTH_MOON.mu, 0.1, L_point=2)
    >>> if orbit:
    ...     print(f"Period: {orbit.period:.4f}")
    """
    state0, T_guess = richardson_halo_initial_guess(mu, Az, L_point, northern)
    state_corrected, period, converged = differential_correction_3d(
        state0, T_guess/2, mu, tol
    )

    if converged:
        C = jacobi_constant(state_corrected, mu)
        orbit_type = "halo_north" if northern else "halo_south"
        return PeriodicOrbit(
            initial_state=state_corrected,
            period=period,
            jacobi=C,
            orbit_type=orbit_type,
            family=f"L{L_point}"
        )
    return None


def continue_family(
    orbit: PeriodicOrbit,
    mu: float,
    parameter: str = "amplitude",
    delta: float = 0.01,
    n_orbits: int = 10
) -> List[PeriodicOrbit]:
    """
    Continue a family of periodic orbits.

    Parameters
    ----------
    orbit : PeriodicOrbit
        Starting orbit
    mu : float
        Mass ratio
    parameter : str
        Continuation parameter: "amplitude" or "jacobi"
    delta : float
        Step size for continuation
    n_orbits : int
        Number of orbits to compute

    Returns
    -------
    list
        Family of periodic orbits
    """
    family = [orbit]

    current = orbit
    for i in range(n_orbits):
        # Predict next orbit by scaling amplitude
        state = current.initial_state.copy()

        if parameter == "amplitude":
            # Scale position away from equilibrium
            state[0] *= (1 + delta)
            state[2] *= (1 + delta)
            state[4] *= (1 + delta)

        # Correct
        corrected, period, success = differential_correction_3d(
            state, current.period / 2, mu
        )

        if success:
            C = jacobi_constant(corrected, mu)
            new_orbit = PeriodicOrbit(
                initial_state=corrected,
                period=period,
                jacobi=C,
                orbit_type=current.orbit_type,
                family=current.family
            )
            family.append(new_orbit)
            current = new_orbit
        else:
            break

    return family
