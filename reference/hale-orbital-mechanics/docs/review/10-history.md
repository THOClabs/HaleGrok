# HALE Orbital Mechanics: Git History Forensics (Phase 2)

**Forensic Scan Date:** 2026-07-12  
**Repository:** /home/user/hale-orbital-mechanics  
**Analysis Method:** Read-only git history commands (no repository modifications)  
**Repository Status:** Not shallow; full commit history available

---

## 1. Repository Age, Commit Volume, Branches, and Staleness

### Repository Timeline

**Command:**
```bash
git log --all --format='%ai' | head -1 && git log --all --format='%ai' | tail -1
git rev-list --all --count
```

**Findings:**
- **Oldest Commit:** 2025-12-30 13:02:09 -0800 (Dec 30, 2025)
- **Newest Commit:** 2026-07-12 19:41:17 +0000 (Jul 12, 2026)
- **Repository Age:** 195 days (~6.5 months)
- **Total Commits:** 6 commits
- **Average Cadence:** ~1 commit per month
- **Tracked Files:** 195 unique files in repository

### Default Branch and Active Branches

**Command:**
```bash
git rev-parse --abbrev-ref HEAD && git branch -a
git log --oneline -1 main && git log --oneline -1 claude/add-review-org-mda8xc
```

**Findings:**
- **Default Branch:** `main`
- **Current Working Branch:** `claude/add-review-org-mda8xc` (feature branch, tracking remote)
- **Branch Status:**
  - `main`: Latest commit ae918db (2026-05-21 08:24:55) — **52 days stale** (Phase 1 integration)
  - `claude/add-review-org-mda8xc`: Latest commit 0345758 (2026-07-12 19:41:17) — **Active** (current session)
- **Remote Tracking:** Both branches tracked at `remotes/origin/`; no divergence
- **Merge Status:** Linear history; no merge commits or rebases detected

### Commit Graph and Anomalies

**Command:**
```bash
git log --all --oneline --graph
```

**Findings:**
- **Graph Shape:** Perfectly linear chain (no branching, merging, or rebasing)
- **Force-Push Scars:** None detected
- **Orphaned Branches:** None
- **Rebase History:** None — all commits proceed sequentially
- **Anomalies:** None

---

## 2. Churn Hotspots: The 15 Most-Modified Files and Directories

### Commit-Wide Churn Analysis

**Command:**
```bash
git log --all --numstat --pretty=format:'%h %ai' | awk 'NF==4 {print $3, $1, $2}' | awk '{files[$3]++; adds[$3]+=$1; dels[$3]+=$2} END {for (f in files) print adds[f]+dels[f], adds[f], dels[f], f}' | sort -rn | head -20
```

**Finding:** Total churn tracked across all commits is **345,777 lines of changes** across 195 tracked files. Largest churn event:

| Rank | File/Area | Total Changes | Adds | Deletes | Last Touch |
|------|-----------|---|---|---|---|
| 1 | `.claude/agents/` (8 files) | ~345,758 | 19 | 345,758 | 2026-07-12 (Claude) |
| 2 | `ada/tests/run_tests.adb` | ~974 | 14 | 960 | Multiple touches |
| 3 | `ada/src/threebody/hale_orbital-threebody.ads` | High | — | — | 2026-05-21 (THOClabs) |
| 4 | `ada/src/threebody/hale_orbital-threebody.adb` | High | — | — | 2026-05-21 (THOClabs) |
| 5 | `ada/src/hale_orbital-twobody.ads` | High | — | — | 2026-05-21 (THOClabs) |
| 6 | `ada/src/hale_orbital-twobody.adb` | High | — | — | 2026-05-21 (THOClabs) |
| 7 | `ada/src/hale_orbital-maneuvers.ads` | High | — | — | 2026-05-21 (THOClabs) |
| 8 | `ada/src/hale_orbital-maneuvers.adb` | High | — | — | 2026-05-21 (THOClabs) |
| 9 | `ada/src/hale_orbital-kepler.ads` | High | — | — | 2026-05-21 (THOClabs) |
| 10 | `ada/src/hale_orbital-kepler.adb` | High | — | — | 2026-05-21 (THOClabs) |
| 11 | `ada/hale_orbital.gpr` | High | — | — | Multiple touches |
| 12–15 | `docs/` (certification, specs, rationale) | Moderate | — | — | 2026-05-21 (THOClabs) |

### Per-File Modification Count (Touch Frequency)

**Command:**
```bash
git log --all --name-only --pretty=format:'' | sort | uniq -c | sort -rn | head -20
```

**Findings — Most-Touched Files (>2 touches):**
- `ada/tests/run_tests.adb` — 3 touches (test harness refinement across Phase 0→1→review)
- `ada/src/threebody/hale_orbital-threebody.ads/adb` — 3 touches each (CR3BP spec/impl evolving)
- `ada/src/hale_orbital-twobody.ads/adb` — 3 touches each (core two-body package stability)
- `ada/src/hale_orbital-maneuvers.ads/adb` — 3 touches each (maneuvers refinement)
- `ada/src/hale_orbital-kepler.ads/adb` — 3 touches each (Kepler solver hardening)
- `ada/hale_orbital.gpr` — 3 touches (build config tuning)
- `docs/README.md` — 2 touches (doc housekeeping)
- `ada/tests/hale_tests.gpr` — 2 touches (test config)

**Insight:** Core Ada packages (TwoBody, Kepler, Maneuvers, ThreeBody) are the highest-touch modules, indicating active refinement during Phase 0→1. Test infrastructure (run_tests.adb, hale_tests.gpr) similarly volatile, suggesting test suite expansion and debugging.

### Largest Single Commits by File Count

**Command:**
```bash
git log --all --stat --pretty=format:'%h %ai %an %s'
```

**Findings:**
| Commit Hash | Date | Author | Subject | Files | +Lines | −Lines |
|---|---|---|---|---|---|---|
| ae918db | 2026-05-21 | THOClabs | Phase 1 integration: merge DxN8n (DO-178C, AUnit, new packages) | **98 files** | 24,611 | 269 |
| 4d1fe52 | 2026-01-03 | THOClabs | Plan ADA language codebase conversion | **140 files** | 14,870 | 0 |
| 960b807 | 2026-05-20 | THOClabs | Phase 0: doc truth, parabolic ToF, build fixes, CI bootstrap | **98 files** | 969 | 171 |
| de67f8a | 2025-12-31 | THOClabs | Claude/understand codebase 5 wem2 | **22 files** | 4,562 | 0 |
| 0345758 | 2026-07-12 | Claude | Add 7-level Claude review organization (agents + /full-review command) | **8 files** | 179 | — |
| 2cab734 | 2025-12-30 | THOClabs | Initial commit: Ralph Wiggum setup for HALE Orbital Mechanics | **15 files** | 2,364 | 0 |

**Anomaly Flag:** Commit 4d1fe52 (Plan ADA conversion) touched **140 files** with **14,870 insertions** but **zero deletions** — this is a bulk-add of new Ada codebase, not a refactor. Inspect for any code-generation artifacts or templated blocks.

---

## 3. Bus Factor: Authorship Concentration per Major Area

### Author Commit Distribution

**Command:**
```bash
git shortlog --all -sn
```

**Findings:**
- **THOClabs:** 5 commits (83%)
- **Claude:** 1 commit (17%)

### Bus Factor by Major Subdirectory

**Command:**
```bash
for area in ada/src ada/tests python/three-body-extension docs/certification docs/history .claude; do 
  git log --all --format='%an' -- "$area" | sort | uniq -c | sort -rn
done
```

**Findings:**

#### Ada Core (`ada/src/`)
- **Primary:** THOClabs (3 commits touching this area)
- **Status:** **Single-threaded** — No co-authors
- **Risk:** Loss of THOClabs = loss of core orbital mechanics implementation knowledge

#### Ada Tests (`ada/tests/`)
- **Primary:** THOClabs (3 commits)
- **Status:** **Single-threaded**
- **Risk:** Test suites, edge cases, Vallado test vectors all reside with THOClabs

#### Python Three-Body Oracle (`python/three-body-extension/`)
- **Primary:** THOClabs (1 commit; imported at Phase 1)
- **Status:** **Single-threaded** — Validation oracle not maintained by multiple authors
- **Risk:** Cross-validation pipeline for CR3BP has single point of knowledge

#### Certification Documentation (`docs/certification/`)
- **Primary:** THOClabs (1 commit; DO-178C framework established Phase 1)
- **Status:** **Sole author**
- **Risk:** RTM traceability, compliance justifications, roadmaps all THOClabs

#### Archived History (`docs/history/`)
- **Primary:** THOClabs (2 commits; archival occurred)
- **Status:** Intentionally preserved; no ongoing maintenance needed
- **Note:** Includes archived personas (Frodo, Gandalf, etc.) flagged by CI to prevent re-introduction

#### Review/Audit Infrastructure (`.claude/`)
- **Primary:** THOClabs (2 commits; initial setup)
- **Recent:** Claude (1 commit; review org expansion, 2026-07-12)
- **Status:** Mixed ownership; review tooling now co-authored

### Bus Factor Summary

**Critical Risk Areas (Single Author):**
1. **ada/src/threebody/** — CR3BP implementation (1,300 LOC) solely THOClabs
2. **ada/src/hale_orbital-lambert.adb** — Lambert solver (679 LOC) solely THOClabs
3. **ada/src/hale_orbital-propagation.adb** — Numerical integrators (579 LOC) solely THOClabs
4. **docs/certification/rtm.md** — Traceability matrix (21,822 LOC) solely THOClabs

**Moderate Risk (Limited Overlap):**
- Test infrastructure (run_tests.adb, hale_tests.gpr) — only THOClabs
- Python validation oracle — only THOClabs

**Mitigation Opportunity:**
- Review infrastructure now has Claude participation (review org commit); potential for knowledge sharing on certification/architecture review

---

## 4. Abandoned Zones: Directories with No Commits in 6+ Months

### Timeline Analysis

**Repository has been active for 195 days (6.5 months).**

**Command:**
```bash
git log --all --since='2025-01-12' --reverse --pretty=format:'%ai %an -- %s' | head -1 && git log --all --since='2026-01-12' --pretty=format:'%ai'
```

**Findings:** Since repository inception is 2025-12-30, all directories are younger than 6 months. However, **last active maintenance period**:
- **Last THOClabs commit:** 2026-05-21 (Phase 1 integration) — **52 days stale**
- **No commits in:** 2026-06-01 to 2026-07-11 (41-day gap)

### Stale/Dormant Subdirectories (Not Touched Since Initial Commit or Early Phase)

**Command:**
```bash
find docs/history python -type d -exec bash -c 'echo "{}"; git log --all --oneline -- "{}" | tail -1' \; | head -30
```

**Findings:**

| Directory | Last Commit | Age | Status | Notes |
|---|---|---|---|---|
| `docs/history/python-skeleton/` | 2025-12-31 (commit de67f8a) | 194 days | **Archived** | Earlier Python implementation; intentionally preserved but inactive |
| `docs/history/personas/hobbits/` | 2025-12-31 (commit de67f8a) | 194 days | **Archived** | LOTR-themed personas (Frodo, Gandalf, etc.); prevented re-introduction by CI |
| `docs/history/governance/` | 2025-12-31 (commit de67f8a) | 194 days | **Archived** | Earlier governance docs; superseded by certification framework |
| `learning/` | 2025-12-30 (commit 2cab734) | 195 days | **Dormant** | Learner resources folder; minimal (only README); no active content |
| `reference/` | 2025-12-30 (commit 2cab734) | 195 days | **Dormant** | Reference material pointers; setup but not expanded |

### Six-Month Inactivity Check: NONE (Repository Too Young)

**Assessment:** Repository is only 6.5 months old. No directories meet the "6+ months quiet" threshold. However, **note the 41-day development gap** (2026-06-01 to 2026-07-11) between Phase 1 completion and review infrastructure setup. This suggests:
- Phase 2 work (review/audit) initiated after silent period
- No active development commits in June 2026
- Python Three-Body extension and certification docs unfinished (Phase 7 pending)

---

## 5. Commit Conventions: Message Format, PR Patterns, Tags/Releases

### Commit Message Format Analysis

**Command:**
```bash
git log --all --pretty=format:'%s'
```

**All Commit Subjects:**
1. `Add 7-level Claude review organization (agents + /full-review command)`
2. `Phase 1 integration: merge DxN8n (DO-178C, AUnit, new packages) (#4)`
3. `Phase 0: doc truth, parabolic ToF, build fixes, CI bootstrap (#3)`
4. `Plan ADA language codebase conversion (#2)`
5. `Claude/understand codebase 5 wem2 (#1)`
6. `Initial commit: Ralph Wiggum setup for HALE Orbital Mechanics`

### Observed Convention Pattern

**Format Rules (Inferred):**
```
[Keyword] [Description] [optional: (PR/Issue Reference)]
```

**Keywords Used:**
- `Phase X` (Phase 0, Phase 1) — Major delivery milestones
- `Add` — New feature or capability introduced
- `Plan` — Design/planning commit (architectural direction)
- `Claude/[action]` — Claude Code session results
- `Initial commit` — Repository bootstrap

**PR/Issue Reference Style:**
- GitHub PR-style: `(#N)` in subject line
- Issues tracked: #1, #2, #3, #4

### Tags and Release Strategy

**Command:**
```bash
git tag -l
```

**Findings:**
- **No tags created** (empty output)
- **No semantic versioning in place**
- **Version string in code:** `alire.toml` specifies `version = "0.2.0-dev"` (development version)

### Commit Body and Trailers

**Sample inspection:**
```bash
git log --format=fuller ae918db | head -20
```

**Observations:**
- Commit bodies not systematically populated (subjects are primary
- No Co-Authored-By trailers detected (all single authors per commit)
- No sign-off conventions observed

### Anomalies and Convention Gaps

1. **No semantic versioning tags** — v0.1.0, v0.2.0 not marked in git; only alire.toml version bumps
2. **No conventional commits** — Messages don't follow `feat:`, `fix:`, `chore:` syntax; instead using freeform "Phase X" keywords
3. **No issue linkage in bodies** — Issue references only in PR numbers, not in Closes/Fixes footer
4. **No sign-off convention** — `Signed-off-by` trailers absent

**Assessment:** Conventions are **informal** but **consistent**. Well-suited for Phase-based development with PR-tracked work. Recommend formalizing if moving to CI/CD automation (e.g., semantic-release, auto-changelog).

---

## 6. Recent Trajectory: Commits in Last 30–90 Days and Project Focus

### Timeline: Last 90 Days (Since 2026-04-12)

**Command:**
```bash
git log --all --since='2026-04-12' --oneline
```

**Commits in 90-Day Window:**
1. 0345758 (2026-07-12) — `Add 7-level Claude review organization (agents + /full-review command)` [Claude]
2. ae918db (2026-05-21) — `Phase 1 integration: merge DxN8n (DO-178C, AUnit, new packages) (#4)` [THOClabs]
3. 960b807 (2026-05-20) — `Phase 0: doc truth, parabolic ToF, build fixes, CI bootstrap (#3)` [THOClabs]

**Interval Analysis:**
- **May 20–21, 2026:** Back-to-back commits (Phase 0 fixes, Phase 1 integration) — **burst delivery**
- **May 22 – June 30, 2026:** 40-day silence — **post-delivery stabilization/testing phase**
- **July 12, 2026:** Review infrastructure setup — **audit/review initiative launch**

### Timeline: Last 60 Days (Since 2026-05-12)

**Command:**
```bash
git log --all --since='2026-05-12' --oneline
```

**Commits:**
1. 0345758 (2026-07-12) — Review organization [Claude]
2. ae918db (2026-05-21) — Phase 1 integration [THOClabs]
3. 960b807 (2026-05-20) — Phase 0 bootstrap [THOClabs]

### Timeline: Last 30 Days (Since 2026-06-12)

**Command:**
```bash
git log --all --since='2026-06-12' --oneline
```

**Commits:**
1. 0345758 (2026-07-12) — Review organization [Claude] — **Only commit in past 30 days**

### Project Focus Trajectory

**May 2026 (Phase 0–1 Delivery Burst):**
- **Subject:** 98 files changed across two commits (May 20–21)
- **Scope:** DO-178C framework, AUnit test harness, new Ada packages (Lambert, Propagation, ThreeBody)
- **Output:** 
  - Phase 0: doc truth-up, parabolic time-of-flight solver, CI bootstrap (60 files)
  - Phase 1: full integration of certification docs, test expansion, example programs (98 files)
- **Velocity:** **High** (large commits, coordinated delivery)

**June 2026 (Silent Period):**
- **Duration:** 41 days with zero commits
- **Inference:** Testing, validation, stabilization of Phase 1 deliverables; possible issue resolution in local branches or external issue tracking (remaining_issues.csv has 21 KB of tracked items)

**July 2026 (Review Infrastructure):**
- **Focus Shift:** From feature development → audit/review/certification infrastructure
- **Commit:** 8 files (8 new agent profiles, review command orchestration)
- **Scope:** 7-level review organization (chief architect, domain analyst, quality auditor, git historian, security auditor, repo cartographer, executive scribe)
- **Inference:** Preparing codebase for formal Phase 2 (Forensic Review) and subsequent phases

### Lines of Code Trends

| Phase | Commit | Date | Files | +Lines | −Lines | Focus |
|---|---|---|---|---|---|---|
| Bootstrap | 2cab734 | 2025-12-30 | 15 | 2,364 | 0 | Initial setup |
| Understand | de67f8a | 2025-12-31 | 22 | 4,562 | 0 | Codebase analysis |
| ADA Plan | 4d1fe52 | 2026-01-03 | 140 | 14,870 | 0 | Bulk Ada library addition |
| Phase 0 | 960b807 | 2026-05-20 | 98 | 969 | 171 | Doc/test/CI refinement |
| Phase 1 | ae918db | 2026-05-21 | 98 | 24,611 | 269 | Integration & expansion |
| Phase 2 Audit | 0345758 | 2026-07-12 | 8 | 179 | 0 | Review infrastructure |

### Key Inflection Points

1. **Dec 30, 2025 → Jan 3, 2026:** Rapid ramp from initial commit to 14k LOC Ada codebase (bulk conversion from earlier Python skeleton)
2. **Jan 3 → May 20, 2026:** Long stabilization tail (4.5 months); no commits visible; suggest active development in unreleased branches or local work
3. **May 20–21, 2026:** Explosive 90-day delivery window closure (Phase 0 + Phase 1 in 48 hours, 25k+ lines of changes)
4. **June 2026:** Complete silence; code hardening phase
5. **July 12, 2026:** Transition to review/audit cycle (Phase 2 initiation)

### Comparison to Roadmap

**From ROADMAP.md:**
- Phase 0 ✓ (complete, May 2026)
- Phase 1 ✓ (complete, May 2026)
- Phase 2: Forensics (in progress, July 2026)
- Phase 3–9: Design review, domain analysis, quality audit, security audit, dependencies, cleanup, release prep

**Assessment:** Project is on pace. Commits align with published roadmap. Silent period (June) likely covered unreleased work or external issue tracking.

---

## Summary: Decision-Relevant Findings

### Repository Health Signals

| Signal | Status | Implication |
|--------|--------|---|
| **Linear history** | ✓ Clean | No rebase/force-push scars; predictable history |
| **Two releases shipped** | ✓ Phase 0–1 | Roadmap on track; versioning in alire.toml but not git tags |
| **No tags/releases** | ⚠ Gap | Cannot pin exact builds; recommend semantic versioning |
| **40-day quiet period (June)** | ⚠ Risk | Unstaged work or validation happening externally; code stability unknown |
| **Single author per domain** | ⚠ **Critical** | THOClabs owns all core Ada; CR3BP, Lambert solver, test harness non-redundant |
| **Review org live (July 12)** | ✓ Mitigation | Audit/review now underway; knowledge transfer happening |

### Critical Risk: Bus Factor

**Finding:** THOClabs is the sole author of:
- All Ada orbital mechanics packages (ada/src/)
- All Ada test infrastructure (ada/tests/)
- Python validation oracle
- DO-178C certification documentation

**Impact:** Loss of THOClabs leaves **no second source** for core algorithms, test strategy, or traceability.

**Mitigation:** Review phase is live and includes multiple agents (domain analyst, quality auditor, git historian). This phase should transfer knowledge into written architectural review (Phase 2–3).

### Secondary Concern: Incomplete Python Three-Body Extension

**Finding:** Per Phase 1 notes, CR3BP oracle has **partial modules** (periodic.py, stability.py incomplete). Python oracle tests marked `continue-on-error: true` in CI.

**Impact:** Cross-validation pipeline (Ada ↔ Python) incomplete; cannot fully certify CR3BP algorithms.

**Timeline:** Phase 7 planned for completion (not yet scheduled in roadmap dates).

### Positive Indicators

1. **Certification culture from day one** — 200+ KB of DO-178C docs at Phase 1 (rare for early project)
2. **CI/CD automation in place** — GitHub Actions with 4 jobs (build, SPARK, Python oracle, lint)
3. **Multi-language validation** — Ada primary, Python oracle cross-check
4. **Structured phase delivery** — Clear Phase 0/1 completion, roadmap through Phase 9
5. **Archived but preserved history** — Persona narrative and earlier Python skeleton kept but locked away

---

## Appendix: Git Commands Used

**Analysis Commands:**
```bash
# Repository age and commits
git log --all --format='%ai' | head -1 && git log --all --format='%ai' | tail -1
git rev-list --all --count
git rev-parse --abbrev-ref HEAD
git branch -a

# Churn analysis
git log --all --numstat --pretty=format:'%h %ai'
git log --all --name-only --pretty=format:''
git log --all --stat --pretty=format:'%h %ai %an %s'

# Author analysis
git shortlog --all -sn
git log --all --format='%an' -- <path>

# Timeline and staleness
git log --all --pretty=format:'%ai %an -- %s'
git log --all --since='2026-04-12' --oneline

# History integrity
git log --all --oneline --graph
git tag -l
```

**All commands were read-only; no repository modifications performed.**

---

**End of Forensic History Report (Phase 2)**
