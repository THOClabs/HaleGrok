"""
HALE Orbital Mechanics Test Suite

Tests are organized to mirror the source structure:
- test_constants.py: Physical constants validation
- test_twobody.py: Two-body problem equations
- test_elements.py: Orbital element conversions
- test_kepler.py: Kepler's equation solvers
- test_lambert.py: Lambert problem solver
- test_maneuvers.py: Orbital maneuvers
- test_interplanetary.py: Patched conic trajectories

Run all tests:
    pytest tests/ -v

Run with coverage:
    pytest tests/ --cov=hale --cov-report=term-missing
"""
