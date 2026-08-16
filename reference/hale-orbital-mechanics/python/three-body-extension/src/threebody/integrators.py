"""
Numerical integration methods for the CR3BP.

Provides Runge-Kutta integrators optimized for orbital mechanics,
including fixed-step (RK4) and adaptive-step (RK45) methods.

For long-term integrations, consider symplectic methods which
better preserve the Jacobi constant (energy-like integral).

References
----------
- Hairer, E. et al. "Geometric Numerical Integration" (2006)
- Press, W.H. et al. "Numerical Recipes" (2007), Chapter 17
"""

import numpy as np
from numpy.typing import NDArray
from typing import Callable, Tuple, Optional, List
from scipy.integrate import solve_ivp
from dataclasses import dataclass

from .cr3bp import equations_of_motion, equations_of_motion_with_stm, jacobi_constant


@dataclass
class IntegrationResult:
    """
    Result of numerical integration.

    Attributes
    ----------
    t : ndarray
        Time points
    y : ndarray
        State vectors at each time point (shape: n_times x 6)
    jacobi : ndarray, optional
        Jacobi constant at each time point (for conservation check)
    success : bool
        Whether integration completed successfully
    message : str
        Status message
    """
    t: NDArray[np.float64]
    y: NDArray[np.float64]
    jacobi: Optional[NDArray[np.float64]] = None
    success: bool = True
    message: str = "Integration completed"


def rk4_step(
    f: Callable,
    t: float,
    y: NDArray[np.float64],
    h: float,
    *args
) -> NDArray[np.float64]:
    """
    Single step of 4th-order Runge-Kutta method.

    Parameters
    ----------
    f : callable
        Right-hand side function f(t, y, *args)
    t : float
        Current time
    y : ndarray
        Current state
    h : float
        Step size
    *args : tuple
        Additional arguments to pass to f

    Returns
    -------
    ndarray
        State at t + h
    """
    k1 = f(t, y, *args)
    k2 = f(t + h/2, y + h*k1/2, *args)
    k3 = f(t + h/2, y + h*k2/2, *args)
    k4 = f(t + h, y + h*k3, *args)

    return y + h * (k1 + 2*k2 + 2*k3 + k4) / 6


def rk45_step(
    f: Callable,
    t: float,
    y: NDArray[np.float64],
    h: float,
    *args,
    tol: float = 1e-10
) -> Tuple[NDArray[np.float64], float, float]:
    """
    Single step of Runge-Kutta-Fehlberg (RK45) method with error estimate.

    Uses 4th and 5th order solutions to estimate error and adapt step size.

    Parameters
    ----------
    f : callable
        Right-hand side function
    t : float
        Current time
    y : ndarray
        Current state
    h : float
        Proposed step size
    *args : tuple
        Additional arguments to pass to f
    tol : float
        Error tolerance

    Returns
    -------
    tuple
        (y_new, h_new, error) - new state, suggested next step, error estimate
    """
    # Butcher tableau coefficients for RK45
    c2, c3, c4, c5, c6 = 1/4, 3/8, 12/13, 1, 1/2

    a21 = 1/4
    a31, a32 = 3/32, 9/32
    a41, a42, a43 = 1932/2197, -7200/2197, 7296/2197
    a51, a52, a53, a54 = 439/216, -8, 3680/513, -845/4104
    a61, a62, a63, a64, a65 = -8/27, 2, -3544/2565, 1859/4104, -11/40

    # 5th order weights
    b1, b3, b4, b5, b6 = 16/135, 6656/12825, 28561/56430, -9/50, 2/55

    # 4th order weights (for error estimate)
    b1s, b3s, b4s, b5s = 25/216, 1408/2565, 2197/4104, -1/5

    k1 = f(t, y, *args)
    k2 = f(t + c2*h, y + h*a21*k1, *args)
    k3 = f(t + c3*h, y + h*(a31*k1 + a32*k2), *args)
    k4 = f(t + c4*h, y + h*(a41*k1 + a42*k2 + a43*k3), *args)
    k5 = f(t + c5*h, y + h*(a51*k1 + a52*k2 + a53*k3 + a54*k4), *args)
    k6 = f(t + c6*h, y + h*(a61*k1 + a62*k2 + a63*k3 + a64*k4 + a65*k5), *args)

    # 5th order solution
    y5 = y + h * (b1*k1 + b3*k3 + b4*k4 + b5*k5 + b6*k6)

    # 4th order solution
    y4 = y + h * (b1s*k1 + b3s*k3 + b4s*k4 + b5s*k5)

    # Error estimate
    error = np.linalg.norm(y5 - y4)

    # Adapt step size
    if error > 0:
        h_new = 0.9 * h * (tol / error) ** 0.2
        h_new = max(h/10, min(h_new, h*5))  # Limit step size changes
    else:
        h_new = h * 2

    return y5, h_new, error


def propagate_fixed_step(
    state0: NDArray[np.float64],
    t_span: Tuple[float, float],
    mu: float,
    dt: float = 0.001,
    with_stm: bool = False
) -> IntegrationResult:
    """
    Propagate state using fixed-step RK4.

    Parameters
    ----------
    state0 : ndarray
        Initial state [x, y, z, vx, vy, vz]
    t_span : tuple
        (t_start, t_end) integration interval
    mu : float
        Mass ratio
    dt : float
        Fixed time step
    with_stm : bool
        If True, also propagate State Transition Matrix

    Returns
    -------
    IntegrationResult
        Integration results with time history
    """
    t0, tf = t_span
    t_values = [t0]

    if with_stm:
        # Initialize STM as identity matrix
        phi0 = np.eye(6).flatten()
        y0 = np.concatenate([state0, phi0])
        y_values = [y0.copy()]
        f = equations_of_motion_with_stm
    else:
        y0 = state0.copy()
        y_values = [y0.copy()]
        f = equations_of_motion

    t = t0
    y = y0.copy()

    while t < tf:
        h = min(dt, tf - t)
        y = rk4_step(f, t, y, h, mu)
        t += h
        t_values.append(t)
        y_values.append(y.copy())

    t_arr = np.array(t_values)
    y_arr = np.array(y_values)

    # Calculate Jacobi constants
    jacobi_arr = np.array([jacobi_constant(y_arr[i, :6], mu) for i in range(len(t_arr))])

    return IntegrationResult(
        t=t_arr,
        y=y_arr,
        jacobi=jacobi_arr,
        success=True,
        message="Fixed-step RK4 integration completed"
    )


def propagate_adaptive(
    state0: NDArray[np.float64],
    t_span: Tuple[float, float],
    mu: float,
    tol: float = 1e-10,
    max_step: float = 0.1,
    dense_output: bool = False
) -> IntegrationResult:
    """
    Propagate state using adaptive RK45 (via scipy).

    Parameters
    ----------
    state0 : ndarray
        Initial state [x, y, z, vx, vy, vz]
    t_span : tuple
        (t_start, t_end) integration interval
    mu : float
        Mass ratio
    tol : float
        Relative and absolute tolerance
    max_step : float
        Maximum step size
    dense_output : bool
        If True, compute dense output for interpolation

    Returns
    -------
    IntegrationResult
        Integration results
    """
    def f(t, y):
        return equations_of_motion(t, y, mu)

    sol = solve_ivp(
        f,
        t_span,
        state0,
        method='RK45',
        rtol=tol,
        atol=tol,
        max_step=max_step,
        dense_output=dense_output
    )

    if sol.success:
        jacobi_arr = np.array([jacobi_constant(sol.y[:, i], mu) for i in range(sol.y.shape[1])])
    else:
        jacobi_arr = None

    return IntegrationResult(
        t=sol.t,
        y=sol.y.T,  # Transpose to match our convention
        jacobi=jacobi_arr,
        success=sol.success,
        message=sol.message
    )


def propagate(
    state0: NDArray[np.float64],
    t_span: Tuple[float, float],
    mu: float,
    method: str = "RK45",
    **kwargs
) -> IntegrationResult:
    """
    Propagate CR3BP state - main interface function.

    Parameters
    ----------
    state0 : ndarray
        Initial state [x, y, z, vx, vy, vz]
    t_span : tuple
        (t_start, t_end) integration interval
    mu : float
        Mass ratio
    method : str
        Integration method: "RK4" (fixed), "RK45" (adaptive)
    **kwargs
        Additional arguments passed to specific integrator

    Returns
    -------
    IntegrationResult
        Integration results

    Example
    -------
    >>> from threebody import propagate, EARTH_MOON
    >>> state0 = np.array([0.5, 0, 0, 0, 0.5, 0])
    >>> result = propagate(state0, (0, 10), EARTH_MOON.mu)
    >>> print(f"Final position: {result.y[-1, :3]}")
    """
    if method.upper() == "RK4":
        return propagate_fixed_step(state0, t_span, mu, **kwargs)
    elif method.upper() in ["RK45", "ADAPTIVE"]:
        return propagate_adaptive(state0, t_span, mu, **kwargs)
    else:
        raise ValueError(f"Unknown method: {method}. Use 'RK4' or 'RK45'.")


def propagate_with_events(
    state0: NDArray[np.float64],
    t_span: Tuple[float, float],
    mu: float,
    events: List[Callable],
    **kwargs
) -> IntegrationResult:
    """
    Propagate with event detection (e.g., x=0 crossing).

    Parameters
    ----------
    state0 : ndarray
        Initial state
    t_span : tuple
        Time span
    mu : float
        Mass ratio
    events : list
        List of event functions. Each should have signature f(t, y) -> float
        and trigger when f = 0.
    **kwargs
        Additional arguments for solve_ivp

    Returns
    -------
    IntegrationResult
        Results including event times in message
    """
    def f(t, y):
        return equations_of_motion(t, y, mu)

    sol = solve_ivp(
        f,
        t_span,
        state0,
        method='RK45',
        events=events,
        **kwargs
    )

    # Collect event times
    event_info = []
    if sol.t_events is not None:
        for i, t_ev in enumerate(sol.t_events):
            if len(t_ev) > 0:
                event_info.append(f"Event {i}: {len(t_ev)} crossings at t={t_ev}")

    jacobi_arr = np.array([jacobi_constant(sol.y[:, i], mu) for i in range(sol.y.shape[1])])

    return IntegrationResult(
        t=sol.t,
        y=sol.y.T,
        jacobi=jacobi_arr,
        success=sol.success,
        message="; ".join(event_info) if event_info else sol.message
    )


# Common event functions
def x_crossing_event(t: float, y: NDArray[np.float64]) -> float:
    """Event function for x = 0 crossing."""
    return y[0]

x_crossing_event.terminal = False
x_crossing_event.direction = 0


def y_crossing_event(t: float, y: NDArray[np.float64]) -> float:
    """Event function for y = 0 crossing."""
    return y[1]

y_crossing_event.terminal = False
y_crossing_event.direction = 0


def periapsis_event_factory(mu: float, primary: int = 2):
    """
    Create event function for periapsis detection.

    Parameters
    ----------
    mu : float
        Mass ratio
    primary : int
        1 for larger primary, 2 for smaller primary
    """
    def periapsis_event(t: float, y: NDArray[np.float64]) -> float:
        x, y_pos, z, vx, vy, vz = y
        if primary == 1:
            r = np.sqrt((x + mu)**2 + y_pos**2 + z**2)
            r_dot = ((x + mu)*vx + y_pos*vy + z*vz) / r
        else:
            r = np.sqrt((x - 1 + mu)**2 + y_pos**2 + z**2)
            r_dot = ((x - 1 + mu)*vx + y_pos*vy + z*vz) / r
        return r_dot

    periapsis_event.terminal = False
    periapsis_event.direction = 1  # Positive to negative = periapsis

    return periapsis_event


def check_jacobi_conservation(
    result: IntegrationResult,
    tol: float = 1e-8
) -> Tuple[bool, float]:
    """
    Check if Jacobi constant is conserved during integration.

    Parameters
    ----------
    result : IntegrationResult
        Integration result with jacobi array
    tol : float
        Tolerance for maximum deviation

    Returns
    -------
    tuple
        (conserved, max_deviation)
    """
    if result.jacobi is None:
        return False, float('nan')

    C0 = result.jacobi[0]
    deviation = np.abs(result.jacobi - C0)
    max_dev = np.max(deviation)

    return max_dev < tol, max_dev
