# History

This directory preserves earlier artefacts that no longer reflect the active state of the codebase. They are kept in-repository for context and provenance; new work does not reference them.

## What lives here

- **`governance/`** — earlier multi-agent collaboration protocols and "summit" / "review-session" / "register" documents. Replaced by the live `docs/ROADMAP.md` and the engineering practice baked into CI.
- **`personas/`** — five Ada-luminary personas (Ichbiah, Taft, Barnes, Dewar, Brosgol) and twelve LOTR Hobbit personas. The technical recommendations in `personas/EXPERT_RECOMMENDATIONS.md` informed several active design decisions (dimensional types as derived; expression functions; status returns inside SPARK; SPARK on pure computational packages) — those decisions are now documented directly in `docs/ARCHITECTURE.md` rather than referenced via persona.
- **`plans/`** — the earlier `HYBRID_PATH_MASTER_PLAN.md` and four sub-plans. These pre-dated the present implementation and described as "spec only, body needs implementation" packages that have since been implemented. Superseded by `docs/ROADMAP.md`.
- **`python-skeleton/`** — the empty `python/src/hale/` package, its `__init__.py`, the never-executed `IMPLEMENTATION_PLAN.md`, the `PROMPT.md` Ralph-Wiggum loop driver, the `CLAUDE.md` Python-implementer guide, the `README.md.bak`, and the `conftest.py` of Hale-example fixtures. The Hale-example reference values in `conftest.py` are still useful — Phase 0 / Phase 1 work ports them into AUnit suite fixtures.

## Why archive instead of delete

The archive preserves the lineage of design decisions and reference values, and lets future readers understand why the codebase looks the way it does. Nothing here is wired into the build.
