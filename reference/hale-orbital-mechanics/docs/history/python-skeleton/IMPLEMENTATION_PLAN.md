# IMPLEMENTATION_PLAN.md - Progress Tracker

**Project:** HALE Orbital Mechanics  
**Source:** Hale, F.J. (1994). *Introduction to Space Flight*. Prentice Hall.  
**Status:** NOT STARTED  
**Last Updated:** [Auto-updated by Ralph loop]

---

## Phase 1: Project Setup & Constants
**Status:** NOT STARTED  
**Validation:** `pytest tests/test_constants.py -v` must pass 100%

### 1.1 Project Infrastructure
- [ ] Create `src/hale/__init__.py` with package setup
- [ ] Create `requirements.txt` with numpy, scipy, pytest
- [ ] Create `tests/__init__.py`
- [ ] Create `tests/conftest.py` with shared fixtures
- [ ] Verify `pip install -e .` works

### 1.2 Physical Constants (Hale Appendix B)
- [ ] Create `src/hale/constants.py` with:
  - [ ] MU_EARTH = 398600.4418 km³/s²
  - [ ] MU_SUN = 132712440018 km³/s²
  - [ ] MU_MOON = 4902.800066 km³/s²
  - [ ] R_EARTH = 6378.137 km
  - [ ] R_SUN = 696000 km
  - [ ] R_MOON = 1737.4 km
  - [ ] AU = 149597870.7 km
  - [ ] G = 6.67430e-20 km³/(kg·s²)
  - [ ] EARTH_ROTATION_RATE = 7.2921159e-5 rad/s
  - [ ] J2_EARTH = 0.00108263
- [ ] Create `tests/test_constants.py`:
  - [ ] Test all constants have correct values
  - [ ] Test all constants have correct units (docstrings)
  - [ ] Test derived values (e.g., Earth surface velocity)

### 1.3 Planetary Data (Hale Table 1.1)
- [ ] Add planetary constants to `constants.py`:
  - [ ] Mercury: μ, R, a, e, i, period
  - [ ] Venus: μ, R, a, e, i, period
  - [ ] Earth: (already done)
  - [ ] Mars: μ, R, a, e, i, period
  - [ ] Jupiter: μ, R, a, e, i, period
  - [ ] Saturn: μ, R, a, e, i, period
- [ ] Create PLANETS dict with all orbital parameters
- [ ] Test planetary data against JPL values (<0.1% error)

**Phase 1 Validation:**
```bash
pytest tests/test_constants.py -v
# Expected: 20+ tests, 100% pass
```

---

## Phase 2: Two-Body Problem (Hale Chapter 2)
**Status:** NOT STARTED  
**Validation:** `pytest tests/test_twobody.py -v` must pass 100%

### 2.1 Fundamental Equations
- [ ] Create `src/hale/twobody.py` with:
  - [ ] `vis_viva(r, a, mu)` → velocity magnitude (Eq 2.20)
  - [ ] `specific_energy(r, v, mu)` → ε = v²/2 - μ/r (Eq 2.16)
  - [ ] `specific_angular_momentum(r, v)` → h = r × v (Eq 2.11)
  - [ ] `semimajor_axis(energy, mu)` → a = -μ/(2ε) (Eq 2.22)
  - [ ] `eccentricity_from_energy(energy, h, mu)` → e (Eq 2.29)
  - [ ] `period(a, mu)` → T = 2π√(a³/μ) (Eq 2.35)
- [ ] Create `tests/test_twobody.py`:
  - [ ] Test vis-viva for circular orbit (v = √(μ/r))
  - [ ] Test vis-viva for escape velocity (v = √(2μ/r))
  - [ ] Test energy is negative for bound orbits
  - [ ] Test energy is zero for parabolic trajectory
  - [ ] Test ISS orbit period (~92 minutes)
  - [ ] Test GEO orbit (a = 42164 km, T = 24h)

### 2.2 Orbit Classification
- [ ] Add orbit type functions:
  - [ ] `orbit_type(e)` → "circular", "elliptical", "parabolic", "hyperbolic"
  - [ ] `is_bound(energy)` → True if ε < 0
  - [ ] `escape_velocity(r, mu)` → v_esc = √(2μ/r)
  - [ ] `circular_velocity(r, mu)` → v_circ = √(μ/r)
- [ ] Test Hale Example 2.1 (Earth satellite)
- [ ] Test Hale Example 2.2 (escape trajectory)

### 2.3 Conic Section Geometry
- [ ] Add conic geometry functions:
  - [ ] `periapsis(a, e)` → r_p = a(1-e)
  - [ ] `apoapsis(a, e)` → r_a = a(1+e)
  - [ ] `radius_at_true_anomaly(a, e, theta)` → r = a(1-e²)/(1+e·cos(θ))
  - [ ] `flight_path_angle(e, theta)` → γ (Eq 2.46)
  - [ ] `velocity_components(r, v, gamma)` → v_r, v_θ
- [ ] Test periapsis/apoapsis for known orbits
- [ ] Test Hale Example 2.3 (flight path angle)

**Phase 2 Validation:**
```bash
pytest tests/test_twobody.py -v
# Expected: 25+ tests, 100% pass
```

---

## Phase 3: Orbital Elements (Hale Chapters 3-4)
**Status:** NOT STARTED  
**Validation:** `pytest tests/test_elements.py -v` must pass 100%

### 3.1 Classical Orbital Elements
- [ ] Create `src/hale/elements.py` with OrbitalElements dataclass:
  - [ ] a: semi-major axis (km)
  - [ ] e: eccentricity (dimensionless)
  - [ ] i: inclination (rad)
  - [ ] Omega: RAAN - right ascension of ascending node (rad)
  - [ ] omega: argument of periapsis (rad)
  - [ ] nu: true anomaly (rad)
- [ ] Add alternative element sets:
  - [ ] M: mean anomaly
  - [ ] E: eccentric anomaly
  - [ ] theta: true anomaly (alias for nu)

### 3.2 State Vector ↔ Elements Conversion
- [ ] Implement `rv_to_elements(r_vec, v_vec, mu)` → OrbitalElements
  - [ ] Calculate h = r × v
  - [ ] Calculate n = k × h (node vector)
  - [ ] Calculate e_vec (eccentricity vector)
  - [ ] Extract all six elements
- [ ] Implement `elements_to_rv(elements, mu)` → (r_vec, v_vec)
  - [ ] Convert elements to perifocal frame
  - [ ] Rotate to inertial frame
- [ ] Create `tests/test_elements.py`:
  - [ ] Test roundtrip: rv → elements → rv (error < 1e-10)
  - [ ] Test Hale Example 4.1 (elements from state)
  - [ ] Test Hale Example 4.2 (state from elements)
  - [ ] Test edge cases: circular (e=0), equatorial (i=0)

### 3.3 Anomaly Conversions
- [ ] Implement anomaly conversion functions:
  - [ ] `true_to_eccentric(nu, e)` → E (Eq 4.13)
  - [ ] `eccentric_to_true(E, e)` → nu (Eq 4.14)
  - [ ] `eccentric_to_mean(E, e)` → M (Kepler's equation)
  - [ ] `mean_to_eccentric(M, e)` → E (iterative solver)
  - [ ] `true_to_mean(nu, e)` → M
  - [ ] `mean_to_true(M, e)` → nu
- [ ] Test anomaly conversions for e = 0, 0.1, 0.5, 0.9
- [ ] Test Hale Example 4.3 (Kepler's equation)

**Phase 3 Validation:**
```bash
pytest tests/test_elements.py -v
# Expected: 30+ tests, 100% pass
```

---

## Phase 4: Kepler's Equation & Time (Hale Chapter 4)
**Status:** NOT STARTED  
**Validation:** `pytest tests/test_kepler.py -v` must pass 100%

### 4.1 Kepler's Equation Solver
- [ ] Create `src/hale/kepler.py` with:
  - [ ] `solve_kepler(M, e, tol=1e-12)` → E (Newton-Raphson)
  - [ ] `solve_kepler_hyperbolic(M, e, tol=1e-12)` → H
  - [ ] `solve_kepler_parabolic(M)` → B (Barker's equation)
- [ ] Test convergence for e = 0.0 to 0.99
- [ ] Test Hale Example 4.4 (Kepler iteration)
- [ ] Test hyperbolic case (e > 1)
- [ ] Test edge case: M = 0, π, 2π

### 4.2 Time of Flight
- [ ] Implement time functions:
  - [ ] `time_since_periapsis(nu, a, e, mu)` → t
  - [ ] `true_anomaly_at_time(t, a, e, mu)` → nu
  - [ ] `time_of_flight(nu1, nu2, a, e, mu)` → Δt
- [ ] Test TOF for quarter orbit, half orbit, full orbit
- [ ] Test Hale Example 4.5 (time of flight)

### 4.3 Universal Variable Formulation
- [ ] Implement universal variable functions:
  - [ ] `stumpff_c(z)` → C(z) (Eq 4.35)
  - [ ] `stumpff_s(z)` → S(z) (Eq 4.36)
  - [ ] `universal_kepler(dt, r0, vr0, a, mu)` → χ
  - [ ] `f_and_g(chi, r0, a, mu)` → f, g, f_dot, g_dot
- [ ] Test Stumpff functions for z < 0, z = 0, z > 0
- [ ] Test f and g functions preserve r × v = h

**Phase 4 Validation:**
```bash
pytest tests/test_kepler.py -v
# Expected: 25+ tests, 100% pass
```

---

## Phase 5: Lambert Problem (Hale Chapter 5)
**Status:** NOT STARTED  
**Validation:** `pytest tests/test_lambert.py -v` must pass 100%

### 5.1 Lambert Solver
- [ ] Create `src/hale/lambert.py` with:
  - [ ] `lambert(r1_vec, r2_vec, tof, mu, prograde=True)` → (v1, v2)
  - [ ] Support short way (Δν < π) and long way (Δν > π)
  - [ ] Support multi-revolution solutions
- [ ] Implement using universal variable method (preferred)
- [ ] Test Hale Example 5.1 (basic Lambert)
- [ ] Test Hale Example 5.2 (multi-rev)

### 5.2 Lambert Validation
- [ ] Test known transfer orbits:
  - [ ] Hohmann transfer Earth-Mars
  - [ ] 180° transfer (degenerate case)
  - [ ] Near-rectilinear transfer
- [ ] Test roundtrip: propagate v1 for tof, verify arrival at r2
- [ ] Test error < 1 km position, < 0.001 km/s velocity

**Phase 5 Validation:**
```bash
pytest tests/test_lambert.py -v
# Expected: 15+ tests, 100% pass
```

---

## Phase 6: Orbital Maneuvers (Hale Chapter 6)
**Status:** NOT STARTED  
**Validation:** `pytest tests/test_maneuvers.py -v` must pass 100%

### 6.1 Hohmann Transfer
- [ ] Create `src/hale/maneuvers.py` with:
  - [ ] `hohmann_transfer(r1, r2, mu)` → (dv1, dv2, tof)
  - [ ] `hohmann_dv_total(r1, r2, mu)` → total Δv
- [ ] Test Hale Example 6.1 (LEO to GEO)
- [ ] Test Hale Example 6.2 (GEO to LEO)

### 6.2 Bi-Elliptic Transfer
- [ ] Implement bi-elliptic transfer:
  - [ ] `bielliptic_transfer(r1, r2, r_intermediate, mu)` → (dv1, dv2, dv3, tof)
  - [ ] `bielliptic_vs_hohmann(r1, r2)` → which is better
- [ ] Test crossover ratio (r2/r1 ≈ 11.94)
- [ ] Test Hale Example 6.3 (bi-elliptic)

### 6.3 Plane Change Maneuvers
- [ ] Implement plane changes:
  - [ ] `plane_change_dv(v, delta_i)` → Δv (Eq 6.15)
  - [ ] `combined_maneuver(v1, v2, delta_i)` → Δv (Eq 6.18)
  - [ ] `optimal_plane_change_location()` → true anomaly
- [ ] Test pure inclination change
- [ ] Test combined altitude + plane change
- [ ] Test Hale Example 6.4 (plane change)

### 6.4 Rendezvous
- [ ] Implement rendezvous functions:
  - [ ] `phase_angle(r_target, r_chaser, mu)` → φ
  - [ ] `wait_time(phase_current, phase_required, n_target)` → t_wait
  - [ ] `coelliptic_rendezvous(r1, r2, phase, mu)` → maneuver sequence
- [ ] Test Hale Example 6.5 (rendezvous)

**Phase 6 Validation:**
```bash
pytest tests/test_maneuvers.py -v
# Expected: 20+ tests, 100% pass
```

---

## Phase 7: Interplanetary Trajectories (Hale Chapters 7-8)
**Status:** NOT STARTED  
**Validation:** `pytest tests/test_interplanetary.py -v` must pass 100%

### 7.1 Sphere of Influence
- [ ] Create `src/hale/interplanetary.py` with:
  - [ ] `sphere_of_influence(a_planet, m_planet, m_sun)` → r_SOI
  - [ ] Earth SOI ≈ 925,000 km
  - [ ] Mars SOI ≈ 577,000 km
- [ ] Test SOI values against Hale Table 7.1

### 7.2 Patched Conic Method
- [ ] Implement departure hyperbola:
  - [ ] `hyperbolic_excess_velocity(v_inf, v_planet)` → v_∞
  - [ ] `departure_dv(r_parking, v_inf, mu)` → Δv
  - [ ] `c3_parameter(v_inf)` → C3 = v_∞²
- [ ] Implement arrival hyperbola:
  - [ ] `arrival_v_inf(v_sc_helio, v_planet)` → v_∞
  - [ ] `capture_dv(r_orbit, v_inf, mu)` → Δv
- [ ] Test Hale Example 7.1 (Earth-Mars patched conic)

### 7.3 Planetary Flyby (Gravity Assist)
- [ ] Implement flyby functions:
  - [ ] `flyby_turning_angle(v_inf, r_periapsis, mu)` → δ
  - [ ] `flyby_dv(v_inf_in, delta, v_planet)` → v_inf_out
  - [ ] `max_turning_angle(v_inf, r_planet, mu)` → δ_max
- [ ] Test Hale Example 7.2 (Jupiter gravity assist)
- [ ] Test Voyager-style trajectory

### 7.4 Synodic Period & Launch Windows
- [ ] Implement launch window functions:
  - [ ] `synodic_period(T1, T2)` → T_syn
  - [ ] `phase_angle_required(r1, r2, tof, mu)` → φ
  - [ ] `launch_window(planet1, planet2, year)` → dates
- [ ] Test Earth-Mars synodic period (~780 days)
- [ ] Test Hale Example 7.3 (launch window)

**Phase 7 Validation:**
```bash
pytest tests/test_interplanetary.py -v
# Expected: 20+ tests, 100% pass
```

---

## Phase 8: Integration & Validation
**Status:** NOT STARTED  
**Validation:** All tests pass, real mission data validates

### 8.1 End-to-End Mission Design
- [ ] Create `src/hale/mission.py` with:
  - [ ] `Mission` class combining all modules
  - [ ] `design_transfer(origin, destination, departure_date)` → mission
  - [ ] `mission_summary()` → printable report
- [ ] Test complete Earth-Mars mission design
- [ ] Test complete Earth-Venus mission design

### 8.2 Real Mission Validation
- [ ] Validate against Apollo 11:
  - [ ] TLI Δv ≈ 3.05 km/s
  - [ ] Transit time ≈ 3 days
  - [ ] LOI Δv ≈ 0.89 km/s
- [ ] Validate against Mars missions:
  - [ ] Hohmann transfer ~259 days
  - [ ] Typical C3 ~8-16 km²/s²
- [ ] Document all validation results in tests

### 8.3 Documentation
- [ ] Complete docstrings for all public functions
- [ ] Add usage examples to README
- [ ] Create Jupyter notebook with worked examples
- [ ] Update Notion project page with completion status

**Phase 8 Validation:**
```bash
pytest tests/ -v
# Expected: 150+ tests, 100% pass
```

---

## Completion Checklist

- [ ] Phase 1: Project Setup & Constants - COMPLETE
- [ ] Phase 2: Two-Body Problem - COMPLETE
- [ ] Phase 3: Orbital Elements - COMPLETE
- [ ] Phase 4: Kepler's Equation & Time - COMPLETE
- [ ] Phase 5: Lambert Problem - COMPLETE
- [ ] Phase 6: Orbital Maneuvers - COMPLETE
- [ ] Phase 7: Interplanetary Trajectories - COMPLETE
- [ ] Phase 8: Integration & Validation - COMPLETE

**Total Items:** 100+  
**Estimated Time:** 76 hours  
**Tests Expected:** 150+

---

## Notes

*Implementation notes will be added here as work progresses*
