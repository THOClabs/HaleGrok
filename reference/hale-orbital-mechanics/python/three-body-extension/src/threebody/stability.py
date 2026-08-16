"""
Stability analysis and invariant manifolds for periodic orbits.

Provides tools for:
- Monodromy matrix computation
- Floquet stability analysis
- Stable/unstable manifold computation
- Manifold globalization

References
----------
- Koon, W.S. et al. "Dynamical Systems, the Three-Body Problem and
  Space Mission Design" (2011), Chapter 4
- Parker, J.S. & Anderson, R.L. "Low-Energy Lunar Trajectory Design" (2014)
"""

import numpy as np
from numpy.typing import NDArray
from typing import Tuple, List, Optional
from dataclasses import dataclass

from .cr3bp import equations_of_motion_with_stm
from .integrators import propagate_fixed_step, IntegrationResult
from .periodic import PeriodicOrbit


@dataclass
class StabilityInfo:
    """
    Stability information for a periodic orbit.

    Attributes
    ----------
    monodromy : ndarray
        6x6 monodromy matrix (STM after one period)
    eigenvalues : ndarray
        Eigenvalues of monodromy matrix
    eigenvectors : ndarray
        Eigenvectors of monodromy matrix
    stability_index : float
        Maximum eigenvalue magnitude (>1 means unstable)
    is_stable : bool
        True if all eigenvalues have magnitude ≤ 1
    unstable_direction : ndarray, optional
        Eigenvector for unstable direction
    stable_direction : ndarray, optional
        Eigenvector for stable direction
    """
    monodromy: NDArray[np.float64]
    eigenvalues: NDArray[np.complex128]
    eigenvectors: NDArray[np.complex128]
    stability_index: float
    is_stable: bool
    unstable_direction: Optional[NDArray[np.float64]] = None
    stable_direction: Optional[NDArray[np.float64]] = None


def compute_monodromy_matrix(
    orbit: PeriodicOrbit,
    mu: float,
    dt: float = 0.0001
) -> NDArray[np.float64]:
    """
    Compute the monodromy matrix for a periodic orbit.

    The monodromy matrix is the State Transition Matrix (STM) evaluated
    after one complete period.

    Parameters
    ----------
    orbit : PeriodicOrbit
        Periodic orbit
    mu : float
        Mass ratio
    dt : float
        Integration step size

    Returns
    -------
    ndarray
        6x6 monodromy matrix
    """
    result = propagate_fixed_step(
        orbit.initial_state,
        (0, orbit.period),
        mu,
        dt=dt,
        with_stm=True
    )

    # Extract final STM
    monodromy = result.y[-1, 6:].reshape((6, 6))

    return monodromy


def analyze_stability(
    orbit: PeriodicOrbit,
    mu: float,
    dt: float = 0.0001
) -> StabilityInfo:
    """
    Perform complete stability analysis of a periodic orbit.

    Parameters
    ----------
    orbit : PeriodicOrbit
        Periodic orbit to analyze
    mu : float
        Mass ratio
    dt : float
        Integration step size

    Returns
    -------
    StabilityInfo
        Complete stability information

    Notes
    -----
    For the CR3BP, the monodromy matrix always has:
    - Two eigenvalues equal to 1 (due to Jacobi constant and time invariance)
    - Eigenvalues come in reciprocal pairs (λ, 1/λ) due to symplectic structure

    The orbit is unstable if any |λ| > 1.
    """
    monodromy = compute_monodromy_matrix(orbit, mu, dt)

    eigenvalues, eigenvectors = np.linalg.eig(monodromy)

    # Sort by magnitude
    idx = np.argsort(np.abs(eigenvalues))[::-1]
    eigenvalues = eigenvalues[idx]
    eigenvectors = eigenvectors[:, idx]

    stability_index = np.max(np.abs(eigenvalues))
    is_stable = stability_index <= 1.0 + 1e-6

    # Find unstable/stable directions (eigenvalues with |λ| > 1 or < 1)
    unstable_dir = None
    stable_dir = None

    for i, lam in enumerate(eigenvalues):
        if np.abs(lam) > 1 + 1e-6 and unstable_dir is None:
            unstable_dir = np.real(eigenvectors[:, i])
            unstable_dir /= np.linalg.norm(unstable_dir)
        elif np.abs(lam) < 1 - 1e-6 and stable_dir is None:
            stable_dir = np.real(eigenvectors[:, i])
            stable_dir /= np.linalg.norm(stable_dir)

    return StabilityInfo(
        monodromy=monodromy,
        eigenvalues=eigenvalues,
        eigenvectors=eigenvectors,
        stability_index=stability_index,
        is_stable=is_stable,
        unstable_direction=unstable_dir,
        stable_direction=stable_dir
    )


def compute_manifold_initial_conditions(
    orbit: PeriodicOrbit,
    stability: StabilityInfo,
    mu: float,
    n_points: int = 100,
    epsilon: float = 1e-6,
    manifold_type: str = "unstable"
) -> List[NDArray[np.float64]]:
    """
    Compute initial conditions on a manifold.

    Parameters
    ----------
    orbit : PeriodicOrbit
        Periodic orbit
    stability : StabilityInfo
        Stability analysis results
    mu : float
        Mass ratio
    n_points : int
        Number of points along the orbit to spawn manifold trajectories
    epsilon : float
        Perturbation magnitude
    manifold_type : str
        "stable" or "unstable"

    Returns
    -------
    list
        Initial conditions for manifold trajectories
    """
    if manifold_type == "unstable":
        direction = stability.unstable_direction
    else:
        direction = stability.stable_direction

    if direction is None:
        return []

    # Propagate orbit to get states at different phases
    dt = orbit.period / n_points
    result = propagate_fixed_step(
        orbit.initial_state,
        (0, orbit.period),
        mu,
        dt=dt / 10,
        with_stm=True
    )

    # Sample points along orbit
    sample_indices = np.linspace(0, len(result.t) - 1, n_points, dtype=int)

    manifold_ics = []
    for idx in sample_indices:
        state = result.y[idx, :6]
        phi = result.y[idx, 6:].reshape((6, 6))

        # Transform eigenvector to current point
        local_direction = phi @ direction
        local_direction /= np.linalg.norm(local_direction)

        # Create perturbations in both directions
        ic_plus = state + epsilon * local_direction
        ic_minus = state - epsilon * local_direction

        manifold_ics.append(ic_plus)
        manifold_ics.append(ic_minus)

    return manifold_ics


def globalize_manifold(
    initial_conditions: List[NDArray[np.float64]],
    mu: float,
    t_span: float,
    direction: int = 1
) -> List[IntegrationResult]:
    """
    Globalize manifold by integrating from initial conditions.

    Parameters
    ----------
    initial_conditions : list
        Initial conditions on manifold
    mu : float
        Mass ratio
    t_span : float
        Integration time
    direction : int
        1 for forward (unstable), -1 for backward (stable)

    Returns
    -------
    list
        Integration results for each trajectory
    """
    from .integrators import propagate_adaptive

    trajectories = []

    for ic in initial_conditions:
        if direction > 0:
            result = propagate_adaptive(ic, (0, t_span), mu)
        else:
            result = propagate_adaptive(ic, (0, -t_span), mu)
        trajectories.append(result)

    return trajectories


def compute_unstable_manifold(
    orbit: PeriodicOrbit,
    mu: float,
    t_span: float = 5.0,
    n_points: int = 50,
    epsilon: float = 1e-6
) -> List[IntegrationResult]:
    """
    Compute and globalize the unstable manifold.

    Parameters
    ----------
    orbit : PeriodicOrbit
        Periodic orbit
    mu : float
        Mass ratio
    t_span : float
        Integration time for manifold trajectories
    n_points : int
        Number of trajectories
    epsilon : float
        Initial perturbation size

    Returns
    -------
    list
        Manifold trajectories
    """
    stability = analyze_stability(orbit, mu)

    if stability.unstable_direction is None:
        return []

    ics = compute_manifold_initial_conditions(
        orbit, stability, mu, n_points, epsilon, "unstable"
    )

    return globalize_manifold(ics, mu, t_span, direction=1)


def compute_stable_manifold(
    orbit: PeriodicOrbit,
    mu: float,
    t_span: float = 5.0,
    n_points: int = 50,
    epsilon: float = 1e-6
) -> List[IntegrationResult]:
    """
    Compute and globalize the stable manifold.

    Parameters
    ----------
    orbit : PeriodicOrbit
        Periodic orbit
    mu : float
        Mass ratio
    t_span : float
        Integration time (backward)
    n_points : int
        Number of trajectories
    epsilon : float
        Initial perturbation size

    Returns
    -------
    list
        Manifold trajectories (integrated backward in time)
    """
    stability = analyze_stability(orbit, mu)

    if stability.stable_direction is None:
        return []

    ics = compute_manifold_initial_conditions(
        orbit, stability, mu, n_points, epsilon, "stable"
    )

    return globalize_manifold(ics, mu, t_span, direction=-1)


def find_heteroclinic_connection(
    orbit1: PeriodicOrbit,
    orbit2: PeriodicOrbit,
    mu: float,
    t_max: float = 10.0,
    tol: float = 0.01
) -> Optional[Tuple[IntegrationResult, IntegrationResult]]:
    """
    Search for heteroclinic connection between two orbits.

    Looks for intersection between unstable manifold of orbit1
    and stable manifold of orbit2.

    Parameters
    ----------
    orbit1 : PeriodicOrbit
        First orbit (compute unstable manifold)
    orbit2 : PeriodicOrbit
        Second orbit (compute stable manifold)
    mu : float
        Mass ratio
    t_max : float
        Maximum propagation time
    tol : float
        Distance tolerance for "intersection"

    Returns
    -------
    tuple or None
        (unstable_traj, stable_traj) if connection found
    """
    # Compute manifolds
    unstable = compute_unstable_manifold(orbit1, mu, t_max, n_points=20)
    stable = compute_stable_manifold(orbit2, mu, t_max, n_points=20)

    if not unstable or not stable:
        return None

    # Search for close approaches
    best_dist = float('inf')
    best_pair = None

    for u_traj in unstable:
        for s_traj in stable:
            # Check minimum distance between trajectories
            for i in range(0, len(u_traj.y), 10):
                for j in range(0, len(s_traj.y), 10):
                    dist = np.linalg.norm(u_traj.y[i, :3] - s_traj.y[j, :3])
                    if dist < best_dist:
                        best_dist = dist
                        best_pair = (u_traj, s_traj)

    if best_dist < tol:
        return best_pair

    return None


def stability_index_string(stability: StabilityInfo) -> str:
    """
    Create human-readable stability description.

    Parameters
    ----------
    stability : StabilityInfo
        Stability information

    Returns
    -------
    str
        Description of stability
    """
    if stability.is_stable:
        return f"Stable (max |λ| = {stability.stability_index:.6f})"
    else:
        return f"Unstable (max |λ| = {stability.stability_index:.6f})"


def eigenvalue_classification(eigenvalues: NDArray[np.complex128]) -> str:
    """
    Classify eigenvalue structure.

    Parameters
    ----------
    eigenvalues : ndarray
        Eigenvalues of monodromy matrix

    Returns
    -------
    str
        Classification string
    """
    # Count eigenvalue types
    n_unit = np.sum(np.abs(np.abs(eigenvalues) - 1) < 1e-6)
    n_real_unstable = np.sum((np.abs(eigenvalues.imag) < 1e-6) & (np.abs(eigenvalues) > 1))
    n_complex = np.sum(np.abs(eigenvalues.imag) > 1e-6)

    parts = []
    if n_unit > 0:
        parts.append(f"{n_unit} unit")
    if n_real_unstable > 0:
        parts.append(f"{n_real_unstable} real unstable")
    if n_complex > 0:
        parts.append(f"{n_complex} complex")

    return ", ".join(parts) if parts else "unknown"
