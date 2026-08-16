#!/usr/bin/env python3
"""
Demonstration of halo orbit computation.

This example shows how to:
1. Find a halo orbit around Earth-Moon L2
2. Propagate it for multiple periods
3. Verify periodicity and Jacobi constant conservation
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

import numpy as np

from threebody.systems import EARTH_MOON
from threebody.lagrange import lagrange_point_L2
from threebody.periodic import (
    richardson_halo_initial_guess,
    find_halo_orbit,
    find_lyapunov_orbit,
)
from threebody.integrators import propagate, check_jacobi_conservation
from threebody.stability import analyze_stability


def demo_lyapunov_orbit():
    """Find a planar Lyapunov orbit."""
    print("=" * 60)
    print("LYAPUNOV ORBIT DEMONSTRATION")
    print("=" * 60)

    system = EARTH_MOON
    mu = system.mu

    print(f"\nSystem: {system.name}")
    print(f"Mass ratio μ = {mu:.6e}")

    # L2 position
    L2 = lagrange_point_L2(mu)
    L2_km = system.to_dimensional_length(L2[0] - (1 - mu))
    print(f"\nL2 location: x = {L2[0]:.6f} (normalized)")
    print(f"             {L2_km:,.0f} km from Moon")

    # Try to find Lyapunov orbit
    print("\nSearching for Lyapunov orbit...")
    Ax = 0.02  # X-amplitude (normalized)

    orbit = find_lyapunov_orbit(mu, Ax, L_point=2, tol=1e-8)

    if orbit:
        print(f"\nLyapunov orbit found!")
        print(f"  Initial state: {orbit.initial_state}")
        print(f"  Period: {orbit.period:.6f} (normalized)")

        # Convert to days
        period_days = system.to_dimensional_time(orbit.period) / 86400
        print(f"  Period: {period_days:.2f} days")
        print(f"  Jacobi constant: {orbit.jacobi:.6f}")

        # Verify by propagation
        result = propagate(
            orbit.initial_state, (0, orbit.period), mu, method="RK45", tol=1e-12
        )

        # Check periodicity
        pos_error = np.linalg.norm(result.y[-1, :3] - result.y[0, :3])
        vel_error = np.linalg.norm(result.y[-1, 3:6] - result.y[0, 3:6])
        print(f"\nPeriodicity check:")
        print(f"  Position error after 1 period: {pos_error:.2e}")
        print(f"  Velocity error after 1 period: {vel_error:.2e}")

        # Jacobi conservation
        conserved, max_dev = check_jacobi_conservation(result)
        print(f"  Jacobi constant max deviation: {max_dev:.2e}")
    else:
        print("Failed to find Lyapunov orbit (differential correction did not converge)")


def demo_halo_orbit():
    """Find a 3D halo orbit."""
    print("\n" + "=" * 60)
    print("HALO ORBIT DEMONSTRATION")
    print("=" * 60)

    system = EARTH_MOON
    mu = system.mu

    print(f"\nSystem: {system.name}")

    # Initial guess using Richardson approximation
    Az = 0.05  # Z-amplitude (normalized)
    print(f"\nGenerating initial guess for L2 halo with Az = {Az}")

    state0, T_guess = richardson_halo_initial_guess(mu, Az, L_point=2, northern=True)
    print(f"Richardson initial guess:")
    print(f"  State: [{state0[0]:.4f}, {state0[1]:.4f}, {state0[2]:.4f}, "
          f"{state0[3]:.4f}, {state0[4]:.4f}, {state0[5]:.4f}]")
    print(f"  Period guess: {T_guess:.4f}")

    # Try to find halo orbit
    print("\nAttempting differential correction...")
    orbit = find_halo_orbit(mu, Az, L_point=2, northern=True, tol=1e-6)

    if orbit:
        print(f"\nHalo orbit found!")
        print(f"  Type: {orbit.orbit_type}")
        print(f"  Initial state: {orbit.initial_state}")
        print(f"  Period: {orbit.period:.6f} (normalized)")

        period_days = system.to_dimensional_time(orbit.period) / 86400
        print(f"  Period: {period_days:.2f} days")
        print(f"  Jacobi constant: {orbit.jacobi:.6f}")

        # Z-amplitude in km
        z_amp_km = system.to_dimensional_length(abs(orbit.initial_state[2]))
        print(f"  Z-amplitude: {z_amp_km:,.0f} km")

        # Stability analysis
        print("\nStability analysis:")
        stability = analyze_stability(orbit, mu, dt=0.001)
        print(f"  Stability index: {stability.stability_index:.4f}")
        print(f"  Is stable: {stability.is_stable}")

        # Dominant eigenvalues
        sorted_eigs = sorted(stability.eigenvalues, key=lambda x: abs(x), reverse=True)
        print(f"  Largest eigenvalue magnitude: {abs(sorted_eigs[0]):.4f}")

    else:
        print("Differential correction did not converge.")
        print("This may require tuning the initial guess or tolerance.")


def demo_propagate_halo():
    """Propagate a halo orbit for multiple periods."""
    print("\n" + "=" * 60)
    print("HALO ORBIT PROPAGATION")
    print("=" * 60)

    system = EARTH_MOON
    mu = system.mu

    # Use a known good initial condition for Earth-Moon L2 halo
    # (These values are approximate and may need correction)
    state0 = np.array([1.15, 0.0, 0.04, 0.0, -0.15, 0.0])
    T_approx = 3.4  # Approximate period

    print(f"\nPropagating test orbit for 3 periods...")
    result = propagate(
        state0, (0, 3 * T_approx), mu, method="RK45", tol=1e-10
    )

    if result.success:
        print(f"Integration successful!")
        print(f"  Time points: {len(result.t)}")
        print(f"  Final time: {result.t[-1]:.2f}")

        # Check Jacobi conservation
        conserved, max_dev = check_jacobi_conservation(result)
        print(f"  Jacobi conservation: {conserved} (max dev: {max_dev:.2e})")

        # Trajectory extent
        x_range = result.y[:, 0].max() - result.y[:, 0].min()
        y_range = result.y[:, 1].max() - result.y[:, 1].min()
        z_range = result.y[:, 2].max() - result.y[:, 2].min()

        print(f"\nTrajectory extent (normalized):")
        print(f"  X: {x_range:.4f}")
        print(f"  Y: {y_range:.4f}")
        print(f"  Z: {z_range:.4f}")


def main():
    """Run all demonstrations."""
    demo_lyapunov_orbit()
    demo_halo_orbit()
    demo_propagate_halo()

    print("\n" + "=" * 60)
    print("Demonstration complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
