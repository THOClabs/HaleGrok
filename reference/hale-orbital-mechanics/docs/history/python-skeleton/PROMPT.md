# PROMPT.md - Ralph Wiggum Loop Driver

You are implementing classical orbital mechanics from Hale's "Introduction to Space Flight" textbook. This prompt will be re-fed to you repeatedly until the project is complete.

## Loop Instructions

**Step 0: Orient**
- Read all specifications in `specs/` folder - these are your source of truth
- Review current state: check `src/`, `tests/`, and git history
- Run `pytest tests/ -v` to see what's passing/failing

**Step 1: Pick ONE Item**
- Open `IMPLEMENTATION_PLAN.md`
- Find the SINGLE highest priority incomplete item (marked `[ ]`)
- Work top-to-bottom within each phase
- Do NOT skip ahead to later phases until current phase is 100% complete

**Step 2: Implement**
- Write code in appropriate `src/hale/` location
- Follow patterns in `CLAUDE.md`
- Reference the specific Hale equations in specs

**Step 3: Test**
- Write tests in `tests/` directory FIRST (TDD)
- Include Hale textbook example problems as test cases
- Validate against known solutions with <0.1% error tolerance

**Step 4: Verify**
```bash
pytest tests/ -v --tb=short
```
- ALL tests must pass (not just new ones)
- If tests fail, debug and fix before proceeding

**Step 5: Update Progress**
- Mark completed item as `[x]` in `IMPLEMENTATION_PLAN.md`
- Add any implementation notes

**Step 6: Commit**
```bash
git add -A
git commit -m "Complete: [item description] - Hale [chapter/equation reference]"
```

**Step 7: Check Phase**
- If all items in current phase are `[x]`, update phase status to COMPLETE
- Proceed to next phase

## Completion Criteria

The project is COMPLETE when:
1. All items in IMPLEMENTATION_PLAN.md are marked `[x]`
2. `pytest tests/ -v` shows 100% pass rate (150+ tests expected)
3. All Hale textbook examples validated to <0.1% error
4. Cross-validation against Vallado reference cases passes

When these conditions are met, output: `<promise>COMPLETE</promise>`

## Current Iteration

Check IMPLEMENTATION_PLAN.md for current status and pick the next incomplete item.

---

## Quick Reference

**Key Constants (Hale Appendix B):**
- μ_Earth = 398600.4418 km³/s²
- μ_Sun = 132712440018 km³/s²
- R_Earth = 6378.137 km
- AU = 149597870.7 km

**Key Equations:**
- Vis-viva: v² = μ(2/r - 1/a)
- Kepler's equation: M = E - e·sin(E)
- Period: T = 2π√(a³/μ)

**Error Tolerance:**
- Position: <1 km for Earth orbits
- Velocity: <0.001 km/s
- Angles: <0.001°
- Time: <1 second
