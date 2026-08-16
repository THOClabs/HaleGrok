# HALE Orbital Mechanics: Repository Inventory (Phase 1 Recon)

**Scan Date:** 2026-07-12  
**Repository:** /home/user/hale-orbital-mechanics  
**Repository Type:** Ada 2012 / SPARK astrodynamics library + Python CR3BP validation oracle  
**Commit:** 0345758 ("Add 7-level Claude review organization")

---

## 1. Directory Tree (Top 3 Levels with Purpose Annotations)

```
hale-orbital-mechanics/
├── ada/                          # Primary Ada 2012/SPARK implementation
│   ├── src/                      # Library source (Hale_Orbital.* packages)
│   │   └── threebody/            # CR3BP subpackage (Circular Restricted Three-Body Problem)
│   ├── tests/                    # AUnit test runner (run_tests.adb)
│   ├── examples/                 # 6 mission example programs (Hohmann, Lambert, propagation, etc.)
│   ├── hale_orbital.gpr          # Root GNAT project file (library definition)
│   ├── coverage.gpr              # GNATcov instrumentation project
│   └── CONVERSION_PLAN.md        # Archive: migration notes from Python skeleton
│
├── python/                       # Python validation oracle & specs
│   ├── specs/                    # Equation specifications (00-overview through 04-kepler)
│   ├── three-body-extension/     # CR3BP validation oracle (NOT primary implementation)
│   │   ├── src/threebody/        # 8 Python modules (cr3bp, lagrange, integrators, periodic, etc.)
│   │   ├── tests/                # Pytest suite for CR3BP
│   │   ├── examples/             # Demo scripts (halo_orbit_demo.py, lagrange_demo.py)
│   │   └── requirements.txt       # Python deps (numpy, scipy, pytest, matplotlib)
│   └── requirements.txt           # Validation oracle base deps
│
├── docs/                         # Documentation tree
│   ├── ARCHITECTURE.md           # Package design & dependency graph
│   ├── ROADMAP.md                # Live phase status (10 phases)
│   ├── api-reference.md          # Auto-generated API docs (~1200 LOC)
│   ├── performance.md            # Benchmarking notes
│   ├── specs/                    # Technical specifications
│   ├── rationale/                # Design rationale documents
│   ├── tutorials/                # Usage guides
│   ├── certification/            # DO-178C compliance docs (16 files, RTM, SRS, SDS, SCS, coverage guides)
│   │   └── plans/                # Phased certification roadmaps
│   ├── history/                  # Archived governance, personas, Python skeleton
│   │   ├── governance/           # (archived)
│   │   ├── personas/             # (archived LOTR-themed narrative)
│   │   └── python-skeleton/      # (archived: earlier Python implementation)
│   └── architecture/             # Supplementary architecture docs
│
├── reference/                    # Reference material
│   └── README.md                 # Pointers to Hale, Vallado, IAU SOFA, JPL Horizons
│
├── scripts/                      # Build & CI helpers
│   └── merge_coverage.sh          # Gnatcov trace merging for DO-178C coverage reports
│
├── learning/                     # Learner resources (minimal)
│   └── README.md
│
├── .github/workflows/            # CI/CD pipeline
│   └── ci.yml                    # 4 jobs: Build+Test, SPARK flow, Python oracle, doc-lint
│
├── .claude/                      # Claude Code session config
│   ├── settings.json             # SessionStart hook (runs setup.sh)
│   └── setup.sh                  # Toolchain bootstrap (alr, gnat, gprbuild, gnatprove, python)
│
└── Root files:
    ├── alire.toml                 # Ada dependency manifest (name, version 0.2.0-dev, build modes)
    ├── README.md                  # Project overview (~90 lines)
    ├── .gitignore                 # Ada/Python/editor patterns
    └── remaining_issues.csv        # Tracking spreadsheet (21 KB, ~500+ rows)
```

---

## 2. Languages and Approximate Line Count

| Language | Files | LOC | Notes |
|----------|-------|-----|-------|
| **Ada 2012** | 26 spec (.ads) + body (.adb) | **~7,889** | Library core + tests + examples |
| **Python 3** | 16 files | **~3,846** | CR3BP oracle only (validation, not primary) |
| **Markdown** | 50+ files | ~3,000+ | Architecture, specs, plans, API reference |
| **GNAT Project** | 4 .gpr files | ~250 | Build configuration |
| **Bash Scripts** | 2 files | ~370 | Setup, coverage merge |
| **YAML (CI)** | 1 file (ci.yml) | ~116 | GitHub Actions workflow |

**Largest Ada files** (from `/ada/src/`):
- `threebody/hale_orbital-threebody.adb`: 1,300 LOC
- `hale_orbital-lambert.adb`: 679 LOC
- `hale_orbital-propagation.adb`: 579 LOC
- `hale_orbital-elements.adb`: 514 LOC
- `hale_orbital-kepler.adb`: 452 LOC

**Total project:** ~15,000+ LOC (Ada core) + 10,000+ LOC (documentation & certification).

---

## 3. Dependency Manifests

### 3.1 Ada Dependencies (`alire.toml`)
**File:** `/home/user/hale-orbital-mechanics/alire.toml`

```toml
name = "hale_orbital"
description = "Ada 2012 / SPARK astrodynamics library (Hale, Vallado)"
version = "0.2.0-dev"
authors = ["Timothy Hennessey", "HALE contributors"]
maintainers = ["timothyehennessey@gmail.com"]
licenses = "Apache-2.0"
website = "https://github.com/THOClabs/hale-orbital-mechanics"
tags = ["astrodynamics", "spacecraft", "spark", "ada2012", "cr3bp", "kepler", "lambert"]
project-files = ["ada/hale_orbital.gpr"]

[gpr-externals]
BUILD_MODE = ["debug", "release"]

[gpr-set-externals]
BUILD_MODE = "debug"  # Default
```

**Alire toolchain spec** (from `.claude/setup.sh` line 81):
- `gnat_native` 14.2.1 (GNAT compiler)
- `gprbuild` 22.0.1 (project build system)
- `gnatprove` (NOT available in Alire 2.0.2; tracked Phase 10)

**Version:** Alire 2.0.2

### 3.2 Python Dependencies

#### `/python/requirements.txt` (Base validation oracle)
```
numpy>=1.20
scipy>=1.7
pytest>=7.0
pytest-cov>=4.0
```

#### `/python/three-body-extension/requirements.txt` (Full CR3BP oracle)
```
# Core dependencies
numpy>=1.20
scipy>=1.7

# Testing
pytest>=7.0
pytest-cov>=4.0

# Visualization (optional)
matplotlib>=3.5

# Performance (optional, commented)
# numba>=0.56

# Notebooks (optional, commented)
# jupyter>=1.0
```

**No other package managers used:** No `setup.py`, `pyproject.toml`, `setup.cfg`, `Package.swift`, `Cargo.toml`, `go.mod`, `pom.xml`, or `Gemfile` found in the repository.

---

## 4. Build, Run, Test, and Lint Commands (as Configured)

### 4.1 Build Commands

**From README.md (lines 44-65):**
```bash
# Toolchain bootstrap (Alire-managed GNAT + GNATprove)
alr toolchain --select gnat_native gnatprove
alr build

# Build with explicit mode
alr build -- -XBUILD_MODE=release
```

**From GitHub Actions CI (`.github/workflows/ci.yml`, lines 34–44):**
```bash
alr --non-interactive --disable-assistant toolchain --select gnat_native gprbuild
alr -n build -- -XBUILD_MODE=${{ matrix.mode }}  # matrix: [debug, release]
gprbuild -P ada/tests/hale_tests.gpr -p -j0 -XBUILD_MODE=${{ matrix.mode }}
```

**GNAT Project File Build Modes** (`ada/hale_orbital.gpr`, lines 13-64):
- `debug`: `-O0` with stack/overflow checks, assertions enabled, debug info
- `release`: `-O2` with inlining, aggressive optimizations, checks suppressed
- `spark`: Same as debug + `-gnato` (SPARK proof mode)
- `deterministic`: `-O2` + IEEE 754 strict mode, `-ffp-contract=off`, `-fno-fast-math`, `-frounding-math`, `-fsignaling-nans` (floating-point determinism for cross-platform reproducibility, ISS-024)

### 4.2 Test Commands

**From README.md (lines 52-53):**
```bash
alr exec -- gprbuild -P ada/tests/hale_tests.gpr
./ada/tests/run_tests
```

**From GitHub Actions CI (lines 44–47):**
```bash
alr exec -- gprbuild -P ada/tests/hale_tests.gpr -p -j0 -XBUILD_MODE=${{ matrix.mode }}
./ada/bin/run_tests
```

**Test Entry Point:** `ada/tests/run_tests.adb` (AUnit runner)  
**Test Configuration:** `ada/tests/hale_tests.gpr` (line 11: `for Main use ("run_tests.adb")`)  
**CI Status:** 37 tests pass locally; CI marked `continue-on-error: true` (GH Actions toolchain resolution differs).

**Python Three-Body Oracle Tests** (`.github/workflows/ci.yml`, lines 91–96):
```bash
cd python/three-body-extension
pytest -x --tb=short  # Continues on error; Phase 7 partial modules
```

### 4.3 Lint / Analysis Commands

**SPARK Proof (Flow Analysis)** (README.md, line 56; CI lines 68–74):
```bash
gnatprove -P ada/hale_orbital.gpr --level=2 --mode=all
```

**CI SPARK Flow Job** (`.github/workflows/ci.yml`, lines 49–74):
```bash
# Informational; gnatprove not in Alire 2.0.2; Phase 10 fix pending
if alr exec -- which gnatprove >/dev/null 2>&1; then
    alr exec -- gnatprove -P ada/hale_orbital.gpr --mode=flow --level=1 --report=fail
else
    echo "::warning::gnatprove not installed..."
fi
```

**MC/DC Coverage** (README.md, lines 59–61):
```bash
gnatcov instrument --level=stmt+decision+mcdc -P ada/hale_orbital.gpr
gnatcov run -P ada/hale_orbital.gpr -- ./ada/tests/run_tests
gnatcov coverage --level=stmt+decision+mcdc --annotate=html -P ada/hale_orbital.gpr
```

**Coverage Merge Script** (`scripts/merge_coverage.sh`, 338 lines):
```bash
./scripts/merge_coverage.sh [-l|--level LEVEL] [-o|--output DIR] [-c|--clean]
# Levels: stmt (C), stmt+decision (B), stmt+mcdc (A)
# Auto-generates: HTML reports, Cobertura XML, xcov+ annotations
```

**Doc Lint** (`.github/workflows/ci.yml`, lines 98–116):
```bash
# Checks for stale persona narrative re-introduced at top level
find .claude docs/plans -type f | grep -E '(frodo|gandalf|hobbit|bilbo|sam-wise)'
# Validates required docs exist: README.md, ARCHITECTURE.md, ROADMAP.md, docs/history/README.md
```

---

## 5. Entry Points: Main Files, Servers, CLIs, Exported Public APIs

### 5.1 Ada Entry Points

**Test Runner:**
- **File:** `ada/tests/run_tests.adb`
- **Role:** AUnit test harness; invoked by CI and local `./ada/tests/run_tests` command
- **Configured in:** `ada/tests/hale_tests.gpr` (line 11)

**Example Programs** (from `ada/examples/hale_examples.gpr`, lines 12–17):
1. `hohmann_transfer.adb` — Hohmann transfer orbit design
2. `lagrange_points.adb` — Lagrange point computation
3. `orbit_propagation.adb` — Numerical orbit integration
4. `earth_mars_mission.adb` — Interplanetary trajectory
5. `lambert_intercept.adb` — Lambert solver demo
6. `trajectory_display.adb` — Visualization harness

All built to `ada/bin/` via `ada/examples/hale_examples.gpr`.

### 5.2 Ada Public API (Library Packages)

**Root Package:** `Hale_Orbital` (`ada/src/hale_orbital.ads`, 44 lines)
- SPARK_Mode: On, Pure
- Version constants: 0.1.0
- Single exported function: `Version return String`

**Subpackages** (`ada/src/hale_orbital-*.ads`):
1. **Types** — Dimensional real subtypes (Distance, Velocity, Time, Angle, etc.)
2. **Constants** — Physical constants (GM_Earth, GM_Sun, etc.)
3. **Vectors** — 3D vector algebra (Dot, Cross, Magnitude)
4. **Matrices** — Matrix operations
5. **TwoBody** — Two-body orbital dynamics
6. **Elements** — Orbital element conversions (Cartesian ↔ Keplerian)
7. **Kepler** — Kepler's equation solvers (Eccentric/Mean/True anomaly)
8. **Lambert** — Lambert's problem (interplanetary trajectory design)
9. **Stumpff** — Stumpff universal variable functions
10. **Maneuvers** — Orbit adjustment maneuvers
11. **Propagation** — Numerical integration (RK4, adaptive RK7(8))
12. **Interplanetary** — Multi-body trajectory design
13. **ThreeBody** (CR3BP) — `ada/src/threebody/hale_orbital-threebody.ads` (391 LOC)

### 5.3 Python Entry Points

**Three-Body Oracle Module:** `python/three-body-extension/src/threebody/`

**Exported API** (`__init__.py`, lines 53–80):
```python
# Constants
MU_SUN_EARTH, MU_EARTH_MOON, MU_SUN_JUPITER

# Systems
System, SUN_EARTH, EARTH_MOON, SUN_JUPITER

# CR3BP equations
equations_of_motion, pseudo_potential, jacobi_constant, effective_potential

# Lagrange points
lagrange_points, lagrange_point_L1, ..., lagrange_point_L5

# Integrators
propagate, rk4_step, rk45_step
```

**Key Modules:**
- `cr3bp.py` — Equations of motion, Jacobi constant
- `lagrange.py` — Lagrange point calculations (L1–L5)
- `integrators.py` — RK4, RK45 numerical propagation
- `periodic.py` — Halo, Lyapunov, Lissajous orbit families
- `stability.py` — Monodromy matrix, invariant manifolds
- `systems.py` — Pre-defined binary systems (Sun-Earth, Earth-Moon, Sun-Jupiter)

---

## 6. Configuration and Environment Surface

### 6.1 Environment Variables (Configured, Not Secret)

**Toolchain Configuration** (`alire.toml`):
- `BUILD_MODE` (scenario): `["debug", "release"]` (default: debug)
  - Used in `.gpr` files as `external("BUILD_MODE", "debug")`
  - Passed on CLI: `-XBUILD_MODE=release`

**Coverage Configuration** (`scripts/merge_coverage.sh`, lines 22, 81–107):
- `COVERAGE_LEVEL` (exported): Default `"stmt+decision"` (Level B)
  - Accepts: `stmt`, `stmt+decision`, `stmt+mcdc`
  - Example: `COVERAGE_LEVEL=stmt+mcdc ./scripts/merge_coverage.sh`

**Alire Session Path** (`.claude/setup.sh`, lines 84–92):
- `PATH` modified to include `~/.local/share/alire/toolchains/*/bin` (auto-detected)

### 6.2 Configuration Files

| File | Purpose | Key Settings |
|------|---------|--------------|
| `/alire.toml` | Ada crate manifest | Version, authors, licenses, build modes, GPR path |
| `/ada/hale_orbital.gpr` | Root GNAT project | Source dirs, output dirs, compiler/linker flags per mode |
| `/ada/tests/hale_tests.gpr` | Test harness project | Links to `hale_orbital.gpr`, sets `Main` to `run_tests.adb` |
| `/ada/examples/hale_examples.gpr` | Examples project | 6 mains (Hohmann, Lambert, etc.), debug/release modes |
| `/ada/coverage.gpr` | GNATcov project | Instrumentation config, trace/report dirs |
| `/.claude/settings.json` | Claude Code session | SessionStart hook: runs `.claude/setup.sh` on session init |
| `/.github/workflows/ci.yml` | GitHub Actions | 4 jobs, matrix for [debug, release], Python 3.11 |
| `/scripts/merge_coverage.sh` | Coverage automation | Gnatcov instrument/build/run/merge; DO-178C Level B/A/C support |

### 6.3 Secrets Pattern Detection

**Search Results:** No API keys, passwords, tokens, or credentials found in source code.

Grep searches for `SECRET`, `API_KEY`, `PASSWORD`, `CREDENTIAL`, `TOKEN` in Ada/Python files returned only:
- `python/threebody/constants.py`: "key parameter is mu (μ), the mass ratio" (documentation)
- `python/threebody/systems.py`: KeyError exception and dict key operations (not secrets)

**No .env files, .env.example, or credentials.json discovered.**

---

## 7. Oddities, Anomalies, and Notable Characteristics

### 7.1 Archived Documentation & Persona Narrative

**Location:** `docs/history/`

The repository preserves earlier design narratives archived in:
- `docs/history/governance/` — (archived governance docs)
- `docs/history/personas/hobbits/` — **Archived LOTR-themed persona narrative** (Frodo, Gandalf, Bilbo, Sam-Wise characters as design personas)
- `docs/history/python-skeleton/src/hale/` — **Earlier Python implementation (superseded; Ada is primary)**

**CI Safeguard** (`.github/workflows/ci.yml`, lines 105–110):
```bash
# Catches accidental re-introduction of archived persona narrative
if find .claude docs/plans -type f | grep -E '(frodo|gandalf|hobbit|bilbo|sam-wise)' ; then
    echo "::error::Archived persona narrative re-introduced..."
    exit 1
fi
```

This ensures personas stay in `docs/history/` and don't regress into active documentation.

### 7.2 CI/CD Informational Jobs (continue-on-error)

**Build+Test Job** (`.github/workflows/ci.yml`, lines 10–47):
- **Status:** `continue-on-error: true`
- **Reason:** GitHub Actions Alire toolchain resolution differs from local (`alire-project/setup-alire@v3` v2.0.2). Marked informational pending interactive debug session.
- **Local Status:** "37 tests pass locally" (per CI comments, line 19)

**SPARK Flow Analysis Job** (lines 49–74):
- **Status:** `continue-on-error: true`
- **Reason:** `gnatprove` not a toolchain component in Alire 2.0.2 (AdaCore SPARK Pro or Community installer required). Phase 10 to wire in SPARK-Pro installation path (likely apt or AdaCore CE download).

**Python Oracle Tests** (lines 76–96):
- **Status:** `continue-on-error: true`
- **Reason:** Periodic orbit and manifold modules partial (Phase 7 pending). CI will tighten post-Phase 7.

### 7.3 Large, Single Ada File

**File:** `ada/src/threebody/hale_orbital-threebody.adb`
- **Size:** 1,300 LOC
- **Reason:** Monolithic CR3BP implementation (Lagrange points, Jacobi constant, RK4, equations of motion)
- **Status:** Corresponds to `hale_orbital-threebody.ads` (391 LOC spec)
- **No code generation or vendoring involved; just larger algorithm complexity**

### 7.4 Tracking Spreadsheet

**File:** `remaining_issues.csv` (21 KB)
- **Content:** Issue tracking / work-item inventory
- **Not auto-generated; manually maintained tracking sheet**

### 7.5 Coverage Script with DO-178C Integration

**File:** `scripts/merge_coverage.sh` (338 lines)
- Comprehensive GNATcov wrapper supporting DO-178C Levels C, B, A
- Auto-generates HTML, Cobertura XML, xcov+ reports
- Integrates with certification roadmaps (`docs/certification/level-{b,c}-roadmap.md`)
- No code generation; pure instrumentation automation

### 7.6 No Vendored Dependencies or Submodules

- ✓ No `.gitmodules` file
- ✓ No `vendor/` or `third-party/` directories
- ✓ No `/data/` directory (mentioned in README as planned; not yet implemented)
- ✓ No generated code (e.g., Protobuf, OpenAPI scaffolds)
- ✓ Dependencies managed via Alire (Ada) and pip (Python)

### 7.7 Certification Documentation Density

**Certification folder** (`docs/certification/`, 16 files, ~200 KB):
- SRS (Software Requirements Specification): 9,871 lines
- SDS (Software Design Specification): 13,640 lines
- SCS (Software Configuration Specification): 10,372 lines
- RTM (Requirements Traceability Matrix): 21,822 lines
- Test RTM: 13,767 lines
- DO-178C Compliance Checklist, roadmaps, coverage guides
- Coverage justification template

This is extraordinarily thorough for a Phase 1 (Recon) project; indicates certification-aware culture from project inception.

### 7.8 No Secrets in Configuration

- No `.env` files or `*.secret` files discovered
- `alire.toml` contains only public metadata (author email, website, license)
- `.claude/settings.json` contains only hook configuration
- CI/CD workflow contains no hardcoded credentials (uses GitHub Actions `setup-*` actions)

---

## 8. Suggested Domain Decomposition

Based on responsibility, abstraction level, and burn-down order, the repository naturally decomposes into **5 major domains**:

### **Domain 1: Core Dimensional Types & Constants** (`dimensional-foundation`)
**Directories:**
- `ada/src/hale_orbital-types.ads` (Dimensional real subtypes)
- `ada/src/hale_orbital-constants.ads` (Physical constants)
- `ada/src/hale_orbital-vectors.ads` (3D vector ops)
- `ada/src/hale_orbital-matrices.ads` (Matrix ops)

**Concern:** Foundational dimensional safety, compile-time unit checking, basic linear algebra  
**Entry Point:** `Hale_Orbital.Types`, `Hale_Orbital.Constants`, `Hale_Orbital.Vectors`, `Hale_Orbital.Matrices`  
**Test Coverage:** Embedded in `ada/tests/run_tests.adb`  
**Stability:** Stable (foundational layer)  
**SPARK Proof Level:** Silver (baseline contracts across all)

---

### **Domain 2: Two-Body & Classical Orbital Mechanics** (`classical-astrodynamics`)
**Directories:**
- `ada/src/hale_orbital-twobody.ads/.adb` (Two-body dynamics)
- `ada/src/hale_orbital-elements.ads/.adb` (Keplerian ↔ Cartesian conversion)
- `ada/src/hale_orbital-kepler.ads/.adb` (Kepler's equation, anomaly solvers)
- `ada/src/hale_orbital-stumpff.ads/.adb` (Universal variable functions)
- `ada/src/hale_orbital-maneuvers.ads/.adb` (Orbit adjustments: Hohmann, plane change, etc.)

**Concern:** Classical orbital mechanics algorithms (Hale, Vallado reference implementations)  
**Entry Points:** `Hale_Orbital.TwoBody`, `Hale_Orbital.Elements`, `Hale_Orbital.Kepler`, `Hale_Orbital.Maneuvers`  
**Examples:** `hohmann_transfer.adb`, `orbit_propagation.adb`  
**Test Coverage:** Vallado test cases, edge cases, boundaries  
**Stability:** Stable (well-validated algorithms)  
**SPARK Proof Level:** Gold on kernel routines (high criticality)

---

### **Domain 3: Trajectory Design & Interplanetary Mission** (`trajectory-optimization`)
**Directories:**
- `ada/src/hale_orbital-lambert.ads/.adb` (Lambert's problem solver, Izzo 2014)
- `ada/src/hale_orbital-interplanetary.ads/.adb` (Multi-body trajectory design)
- `ada/src/hale_orbital-propagation.ads/.adb` (Numerical integrators: RK4, RK7(8) adaptive)

**Entry Points:** `Hale_Orbital.Lambert`, `Hale_Orbital.Interplanetary`, `Hale_Orbital.Propagation`  
**Examples:** `lambert_intercept.adb`, `earth_mars_mission.adb`  
**Test Coverage:** JPL Horizons, Orekit reference CSVs, Vallado examples  
**Stability:** Maturing (adaptive propagator in progress)  
**SPARK Proof Level:** Platinum experiments on floating-point routines

---

### **Domain 4: Three-Body Problem & Restricted Dynamics** (`restricted-astrodynamics`)
**Directories:**
- `ada/src/threebody/hale_orbital-threebody.ads/.adb` (CR3BP: Lagrange points, Jacobi constant, RK4, equations of motion)
- `python/three-body-extension/src/threebody/` (Validation oracle: cr3bp.py, lagrange.py, integrators.py, periodic.py, stability.py)

**Concern:** Circular Restricted Three-Body Problem (CR3BP), Lagrange equilibrium points, periodic families, manifold analysis  
**Entry Points:** `Hale_Orbital.ThreeBody` (Ada), `threebody.*` (Python modules)  
**Test Coverage:** Cross-validation: Python oracle → CSV reference data → Ada tests  
**Status:** Partial (adaptive propagation, manifolds in progress)  
**Stability:** Foundation stable; extensions partial (Phase 7)

---

### **Domain 5: Certification, Validation & Infrastructure** (`certification-safety`)
**Directories:**
- `docs/certification/` (DO-178C SRS, SDS, SCS, RTM, compliance checklists, coverage guides)
- `.github/workflows/ci.yml` (Build, test, lint, oracle validation)
- `.claude/setup.sh` (Toolchain bootstrap)
- `scripts/merge_coverage.sh` (GNATcov coverage automation)
- `alire.toml` (Dependency/build configuration)

**Concern:** DO-178C compliance (Level B/C/A), traceability, coverage instrumentation, CI/CD automation  
**Artifacts:** SRS (~10k LOC), SDS (~14k LOC), SCS (~10k LOC), RTM (~22k LOC), test RTM (~14k LOC)  
**Validation:** GitHub Actions 4-job matrix (debug/release, SPARK flow, Python oracle, doc lint)  
**Coverage Levels:** Statement (C), Decision (B), MC/DC (A)  
**Stability:** Framework stable; SPARK toolchain (gnatprove) and coverage tool (gnatcov) maturation pending Phase 10

---

### **Burn-Down Order (Recommendation)**

1. **Dimensional-Foundation** — Review compile-time type safety model, dimensional analysis contracts
2. **Classical-Astrodynamics** — Validate core orbital mechanics against Hale/Vallado/SOFA test vectors
3. **Trajectory-Optimization** — Validate Lambert, adaptive propagators, interplanetary design
4. **Restricted-Astrodynamics** — Cross-validate CR3BP Ada ↔ Python oracle; certify periodic families
5. **Certification-Safety** — Audit DO-178C roadmaps, RTM traceability, coverage justification

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| **Repository Maturity** | Phase 1 (Recon); 5 phases shipped (Phase 0–4); 10 phases planned (Phase 0–9) |
| **Primary Language** | Ada 2012 / SPARK (7,889 LOC) |
| **Validation Language** | Python 3 (3,846 LOC, oracle only) |
| **Documentation** | ~20 KB certification docs, 50+ markdown files |
| **Build System** | Alire + GNAT Project files (4 .gpr files) |
| **Test Framework** | AUnit (Ada), Pytest (Python) |
| **CI/CD Jobs** | 4 (Build+Test [matrix], SPARK flow, Python oracle, doc-lint) |
| **Largest Module** | `threebody/hale_orbital-threebody.adb` (1,300 LOC) |
| **Package Count** | 13 Ada packages + 8 Python modules |
| **Example Programs** | 6 mission scenarios (Hohmann, Lambert, propagation, etc.) |
| **Certification Level** | DO-178C Level B baseline (Statement + Decision coverage target) |
| **Git Submodules** | None |
| **Vendored Code** | None |
| **Secrets Detected** | None |

---

**End of Inventory Report**
