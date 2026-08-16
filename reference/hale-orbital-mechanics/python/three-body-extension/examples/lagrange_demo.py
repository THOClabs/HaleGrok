#!/usr/bin/env python3
"""
Demonstration of Lagrange point calculations.

This example shows how to:
1. Calculate all 5 Lagrange points for different systems
2. Convert to physical units (km)
3. Analyze stability
4. Visualize the effective potential
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

import numpy as np

from threebody.systems import SUN_EARTH, EARTH_MOON, get_system
from threebody.lagrange import (
    lagrange_points,
    lagrange_point_jacobi_constants,
    is_L4_L5_stable,
    linearized_dynamics_at_lagrange,
    classify_lagrange_point,
)
from threebody.cr3bp import effective_potential


def demo_lagrange_points():
    """Calculate and display Lagrange points for Sun-Earth system."""
    print("=" * 60)
    print("LAGRANGE POINTS DEMONSTRATION")
    print("=" * 60)

    # Sun-Earth System
    print("\n--- Sun-Earth System ---")
    system = SUN_EARTH
    print(f"Mass ratio μ = {system.mu:.6e}")
    print(f"Distance unit = {system.distance:,.0f} km")

    L = lagrange_points(system.mu)
    C = lagrange_point_jacobi_constants(system.mu)

    print("\nLagrange Point Positions:")
    print("-" * 50)
    for i, (pos, jacobi) in enumerate(zip(L, C), 1):
        x_km = system.to_dimensional_length(pos[0])
        if pos[1] != 0:
            y_km = system.to_dimensional_length(pos[1])
            print(f"L{i}: x = {pos[0]:.6f}, y = {pos[1]:.6f}")
            print(f"     ({x_km/1e6:.2f} million km, {y_km/1e6:.2f} million km)")
        else:
            # Distance from Earth (primary 2)
            dist_from_earth = abs(pos[0] - (1 - system.mu))
            dist_km = system.to_dimensional_length(dist_from_earth)
            print(f"L{i}: x = {pos[0]:.6f}")
            print(f"     {dist_km/1e6:.2f} million km from Earth")
        print(f"     Jacobi constant C = {jacobi:.6f}")

    # Stability analysis
    print("\nStability Analysis:")
    print("-" * 50)
    for i, pos in enumerate(L, 1):
        A, eigenvalues = linearized_dynamics_at_lagrange(pos, system.mu)
        classification = classify_lagrange_point(eigenvalues)
        print(f"L{i}: {classification}")

    # L4/L5 stability
    print(f"\nL4/L5 linearly stable: {is_L4_L5_stable(system.mu)}")
    print(f"(Routh critical value: μ < 0.0385)")

    # Earth-Moon System
    print("\n" + "=" * 60)
    print("--- Earth-Moon System ---")
    system = EARTH_MOON
    print(f"Mass ratio μ = {system.mu:.6e}")
    print(f"Distance unit = {system.distance:,.0f} km")

    L = lagrange_points(system.mu)

    print("\nKey Lagrange Points:")
    print("-" * 50)

    # L1
    dist_L1 = abs(L[0][0] - (1 - system.mu))
    dist_L1_km = system.to_dimensional_length(dist_L1)
    print(f"L1: {dist_L1_km:,.0f} km from Moon (Earthward)")

    # L2
    dist_L2 = abs(L[1][0] - (1 - system.mu))
    dist_L2_km = system.to_dimensional_length(dist_L2)
    print(f"L2: {dist_L2_km:,.0f} km from Moon (far side)")
    print("    → Future Lunar Gateway location!")

    print(f"\nL4/L5 linearly stable: {is_L4_L5_stable(system.mu)}")


def demo_effective_potential():
    """Show effective potential landscape."""
    print("\n" + "=" * 60)
    print("EFFECTIVE POTENTIAL")
    print("=" * 60)

    system = EARTH_MOON
    mu = system.mu

    # Create grid
    x = np.linspace(-1.5, 1.5, 200)
    y = np.linspace(-1.5, 1.5, 200)
    X, Y = np.meshgrid(x, y)

    # Calculate potential (avoiding singularities at primaries)
    Omega = effective_potential(X, Y, mu)

    # Find min/max for reasonable range
    Omega_clipped = np.clip(Omega, 1.0, 5.0)

    print("\nEffective potential calculated on 200x200 grid")
    print(f"Range: [{np.min(Omega_clipped):.2f}, {np.max(Omega_clipped):.2f}]")

    # Lagrange point potentials
    L = lagrange_points(mu)
    print("\nPotential at Lagrange points:")
    for i, pos in enumerate(L, 1):
        omega = effective_potential(np.array([[pos[0]]]), np.array([[pos[1]]]), mu)
        print(f"  L{i}: Ω = {omega[0,0]:.4f}")


def main():
    """Run all demonstrations."""
    demo_lagrange_points()
    demo_effective_potential()

    print("\n" + "=" * 60)
    print("Demonstration complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
