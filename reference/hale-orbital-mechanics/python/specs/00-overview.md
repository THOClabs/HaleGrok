# Spec 00: Project Overview

## Source Material

**Primary Reference:**
- Hale, Francis J. *Introduction to Space Flight*. Englewood Cliffs, NJ: Prentice Hall, 1994.
- ISBN: 0-13-481912-8
- 366 pages, 8 chapters + appendices

## Textbook Structure

| Chapter | Title | Implementation Module |
|---------|-------|----------------------|
| 1 | Introduction to Space Flight | (context only) |
| 2 | The Two-Body Problem | `twobody.py` |
| 3 | Position and Velocity | `elements.py` |
| 4 | Orbital Elements | `elements.py`, `kepler.py` |
| 5 | The Lambert Problem | `lambert.py` |
| 6 | Orbital Maneuvers | `maneuvers.py` |
| 7 | Interplanetary Trajectories | `interplanetary.py` |
| 8 | Lunar Trajectories | `interplanetary.py` |
| App A | Vector Review | (not implemented) |
| App B | Physical Constants | `constants.py` |

## Design Philosophy

### 1. Textbook Traceability

Every function maps to a specific equation:
```python
def vis_viva(r, a, mu):
    """
    Reference: Hale Eq. 2.20, p. 45
    """
```

### 2. Classical Methods First

Implement Hale's analytical methods before numerical:
- Two-body analytical solutions
- Kepler's equation (Newton-Raphson)
- Lambert (universal variable)
- Patched conics (not numerical integration)

### 3. Validation Against Examples

Every Hale worked example becomes a test case:
- Example 2.1 → `test_hale_example_2_1()`
- Example 4.4 → `test_hale_example_4_4()`
- etc.

## Scope

### In Scope

- Two-body problem (Keplerian orbits)
- Orbital elements conversions
- Kepler's equation solvers
- Lambert problem (single and multi-rev)
- Hohmann and bi-elliptic transfers
- Plane change maneuvers
- Patched conic interplanetary
- Gravity assist calculations

### Out of Scope (Future Phases)

- N-body numerical propagation
- Perturbations (J2, drag, solar pressure)
- Attitude dynamics
- Launch vehicle trajectories
- Re-entry dynamics
- Station-keeping
- Constellation design

## Success Criteria

1. **Completeness:** All 8 priority chapters implemented
2. **Accuracy:** <0.1% error on validated test cases
3. **Traceability:** 100% code ↔ textbook ↔ validation
4. **Test Coverage:** 150+ tests, 100% pass rate
5. **Real-World Validation:** Apollo, Mars missions match

## Dependencies

```
numpy>=1.20
scipy>=1.7
pytest>=7.0
```

No orbital mechanics libraries (astropy, poliastro) - this IS the library.

## Timeline

| Phase | Duration | Hours |
|-------|----------|-------|
| 1: Setup & Constants | Week 1 | 8 |
| 2: Two-Body | Weeks 2-3 | 12 |
| 3: Orbital Elements | Weeks 3-4 | 12 |
| 4: Kepler | Week 4-5 | 10 |
| 5: Lambert | Week 5-6 | 10 |
| 6: Maneuvers | Weeks 6-7 | 10 |
| 7: Interplanetary | Weeks 7-8 | 10 |
| 8: Integration | Weeks 9-10 | 4 |
| **Total** | **10 weeks** | **76 hours** |
