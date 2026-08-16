"""
Three-Body Extension Test Suite

Tests organized by module:
- test_constants.py: Mass ratios and system definitions
- test_cr3bp.py: Equations of motion, Jacobi constant
- test_lagrange.py: Lagrange point calculations
- test_integrators.py: Numerical integration methods
- test_periodic.py: Periodic orbit finding
- test_stability.py: Stability analysis and manifolds

Run all tests:
    pytest tests/ -v

Run with coverage:
    pytest tests/ --cov=threebody --cov-report=term-missing
"""
