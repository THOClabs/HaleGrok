# Domain Report: Certification, Validation & Infrastructure (`certification-safety`)

**Reviewer:** Domain Analyst (L3), Phase 3 Deep Dive
**Scope:** `docs/certification/`, `.github/workflows/ci.yml`, `.claude/setup.sh`, `.claude/settings.json`, `scripts/merge_coverage.sh`, `alire.toml`, `ada/*.gpr`, `ada/tests/` (as verification-infrastructure evidence, not per-algorithm correctness)
**Method:** Static reading + live execution of `.claude/setup.sh` in this sandbox to confirm reported failure modes (read-only w.r.t. the repository; installs land under `~/.local`, not the repo).

---

## 1. Responsibility

This domain packages the DO-178C paper trail (PSAC/SDP/SQAP/SCMP/SVP plans, SRS, SDS, SCS, RTM, test-RTM, roadmaps) that claims traceability from textbook-derived requirements through Ada contracts to tests, and it owns the build/toolchain/CI scaffolding (Alire, GNAT project files, GitHub Actions, the coverage-merge script, and the Claude session bootstrap) that is supposed to produce and gate that evidence. In practice it is two loosely-coupled halves: an extensive, self-critical certification documentation set, and a much thinner, partially-wired automation layer that does not yet make the documentation's claims true.

## 2. Key Modules

**CI / toolchain:**
- `.github/workflows/ci.yml:10-47` — `build-and-test` job: Alire toolchain select → `alr build` (debug/release matrix) → build `ada/tests/hale_tests.gpr` → run `./ada/bin/run_tests`. `continue-on-error: true` (line 21).
- `.github/workflows/ci.yml:49-74` — `spark-flow` job: conditional `gnatprove` flow analysis, informational only (`continue-on-error: true`, line 56).
- `.github/workflows/ci.yml:76-96` — `python-oracle` job: pytest for the CR3BP oracle; failures are swallowed inline (`pytest -x --tb=short || echo "::warning..."`, line 96) rather than via `continue-on-error`.
- `.github/workflows/ci.yml:98-116` — `doc-lint` job: greps for reintroduced persona narrative and checks required docs exist; the only job with real `exit 1` paths not wrapped in `||`.
- `.claude/setup.sh` — SessionStart toolchain bootstrap: `install_alire` (lines 32-70), `install_toolchain` (74-98), `install_python_oracle` (102-113), `main` (117-134).
- `.claude/settings.json:4-14` — wires `bash .claude/setup.sh 2>&1 | tail -40` into the `SessionStart` hook.
- `scripts/merge_coverage.sh` (338 lines) — gnatcov instrument/build/run/merge wrapper for DO-178C Level C/B/A coverage; standalone, not called from `ci.yml`.
- `alire.toml` — crate manifest; no `[[depends]]` section (no declared Ada dependencies, e.g. no AUnit), no lockfile in the repo.
- `ada/hale_orbital.gpr` — root project; four build modes: `debug`, `release`, `spark`, `deterministic` (lines 13, 32-64).
- `ada/coverage.gpr` — GNATcov instrumentation project; `Main => test_driver_coverage.adb` (line 12), lists all 13 library units under `package Units` (lines 76-90), matching `ada/src/*.ads` exactly.
- `ada/tests/hale_tests.gpr` — CI-facing test project; `Main => run_tests.adb` only (line 11).

**Test-harness code (verification infrastructure, not correctness):**
- `ada/tests/run_tests.adb` (742 lines) — the harness CI actually builds and runs. Self-contained: does not `with` any `Hale_Tests.*` package. 64 `Run_Test` calls (grep count). Prints a pass/fail summary but **never calls `Ada.Command_Line.Set_Exit_Status`** — the process always exits 0.
- `ada/tests/hale_tests-runner.ads/.adb` — shared AUnit-flavored assertion package; `Assert*` procedures `raise Constraint_Error` on failure (`hale_tests-runner.adb:25,35,46,61,78,88,97,108`), but `Run_Test(name, condition)` (used by nearly every suite) only increments counters — never raises.
- `ada/tests/hale_tests-vallado.adb`, `-edge_cases.adb`, `-negative.adb`, `-exceptions.adb`, `-boundaries.adb`, `-determinism.adb`, `-integration.adb`, `-lambert_multirev.adb` — all use the non-raising `Run_Test`/`Runner.Run_Test` pattern (confirmed via grep on each file).
- `ada/tests/hale_tests-periodic_orbits.adb`, `-parallel.adb` — do not even `with Hale_Tests.Runner`; each defines its own local pass/fail counter (`Report_Test`, `Tests_Passed`/`Tests_Failed`) that is printed but never checked by a caller.
- `ada/tests/test_driver_coverage.adb` (278 lines) — `Main` of `ada/coverage.gpr`. Wires 6 of the ~10 suite packages (Vallado, Edge_Cases, Negative, Exceptions, Boundaries, Periodic_Orbits — lines 18-24, 144-155). Does call `CL.Set_Exit_Status` (lines 272-276), but the condition it checks, `Results.Failed_Tests`, is only incremented when a whole suite procedure raises an *uncaught* exception (line 133); it never inspects `Hale_Tests.Runner.Tests_Failed`/`Total_Tests`. Its own `Coverage_Results.Total_Tests` field (line 39) is declared and never incremented anywhere in the file.
- `ada/tests/run_all_tests.adb` (388 lines) — the most complete runner: wires all 8 extended suites plus core suites, and correctly calls `CLI.Set_Exit_Status` based on `Runner.Tests_Failed` (lines 382-386). **Not referenced as `Main` by any `.gpr` file in the repo** (only self-reference and a mention in `remaining_issues.csv:2`) — it is dead code from a build-and-run perspective.

## 3. Data Flow: requirement → code → test → RTM, and how CI gates a change

1. **Requirement authored:** A high-level requirement is written in `docs/certification/SRS.md` under an ID like `HLR-1A-001` (`SRS.md:47`), citing a Hale/Vallado chapter/equation.
2. **Design mapped:** `docs/certification/SDS.md` describes the architecture/package structure that will satisfy it (§3, lines 75-238) — but SDS.md contains **zero occurrences of any `HLR-*` requirement ID** (confirmed by grep), so the mapping from SRS requirement to SDS design section is prose-only, not ID-traceable.
3. **Implementation:** the requirement is realized as an Ada function with `Pre`/`Post` contracts in `ada/src/hale_orbital-*.ads` (e.g. `Hale_Orbital.Kepler.Solve_Kepler_Elliptic`).
4. **Traceability recorded twice, inconsistently:** `docs/certification/rtm.md` records the same kind of mapping but under a **different ID scheme** — `HLR-TB-001`, `HLR-OE-*`, `HLR-KE-*`, `HLR-LB-*`, `HLR-MN-*`, `HLR-IP-*`, `HLR-3B-*` (`rtm.md:21-31`, `rtm.md:41` uses `HLR-TB-001`). Grep confirms `rtm.md` contains 16 occurrences of `HLR-TB` and **zero** of `HLR-1A`; `SRS.md` and `test-rtm.md` contain 11 and 26 occurrences of `HLR-1A` respectively and **zero** of `HLR-TB`. The RTM and the SRS/test-RTM do not share a requirement-ID namespace — the "bidirectional traceability" the RTM claims (`rtm.md:13`) cannot actually be walked mechanically between these two documents.
5. **Test evidence claimed:** `docs/certification/test-rtm.md:20-33` lists 10 test packages (`hale_tests-vallado` 25 tests, `hale_tests-edge_cases` 60+, `hale_tests-determinism` 12, `hale_tests-parallel` 8, `hale_tests-integration` 15, `hale_tests-lambert_multirev` 10, `hale_tests-periodic_orbits` 18, `hale_tests-negative` 32, `hale_tests-exceptions` 24, `hale_tests-boundaries` 30 — 234 tests total) each marked "✓ Complete".
6. **What CI actually builds and runs:** `ci.yml:44` builds `ada/tests/hale_tests.gpr`, whose only `Main` is `run_tests.adb` (`hale_tests.gpr:11`). `run_tests.adb` never references the `Hale_Tests.*` package hierarchy at all (own local suite functions, 64 assertions). So **none of the 234 "✓ Complete" tests in the test-RTM are built or executed by the pipeline that gates pushes/PRs.** They are only reachable via `ada/coverage.gpr` (6 of 10 suites, local-only, invoked by `scripts/merge_coverage.sh` which `ci.yml` never calls) or via the orphaned `run_all_tests.adb` (all 10, but not built by any `.gpr` `Main` at all).
7. **CI gating in practice:** even the one suite CI does run (`run_tests.adb`) cannot fail the job on assertion failure, because it never calls `Ada.Command_Line.Set_Exit_Status` — the process exits 0 regardless of how many `[FAIL]` lines it prints. Combined with `continue-on-error: true` on the `build-and-test` job itself (`ci.yml:21`), there are now two independent reasons a broken build/test would not turn the PR check red.
8. **Coverage instrumentation:** `scripts/merge_coverage.sh` and `ada/coverage.gpr` implement the DO-178C statement/decision/MC-DC workflow described in `docs/certification/coverage-guide.md`, but no GitHub Actions workflow invokes them — `coverage-guide.md:302-303` and `level-b-roadmap.md:82` both reference `.github/workflows/coverage.yml`, which does not exist (`.github/workflows/` contains only `ci.yml`, confirmed by directory listing).

## 4. External Dependencies

- **Alire 2.0.2** (`alire-project/setup-alire@v3`, `ci.yml:30-32,60-63`) — resolves `gnat_native` and `gprbuild` toolchain components. `gnatprove` is explicitly **not** an Alire 2.0.2 toolchain component (`ci.yml:52-55`, `spark-scope.md` assumes it is available via `gnatprove -P ... --level=2`, which is aspirational).
- **GNAT 14 / gprbuild 22** — versions asserted in `.claude/setup.sh` comments and `00-inventory.md`, not pinned anywhere machine-checkable in this repo (no `alire.lock`/pin file found).
- **GNATcoverage (gnatcov)** — required by `scripts/merge_coverage.sh:155-158` (hard `exit 1` if absent) and `ada/coverage.gpr`; never confirmed present in CI since no workflow step installs or invokes it.
- **GitHub Actions** — `actions/checkout@v4`, `actions/setup-python@v5`, `alire-project/setup-alire@v3`. No third-party or unpinned-by-SHA actions beyond version tags.
- **Python 3.11 + numpy/scipy/pytest** (`ci.yml:81-89`) — feeds the `python-oracle` job; cross-domain touchpoint into the `restricted-astrodynamics` (CR3BP) domain, not analyzed here beyond the CI wiring.
- **Network dependency for toolchain bootstrap:** `.claude/setup.sh:20,44` fetches `alr-2.0.2-bin-x86_64-linux.zip` directly from `github.com/alire-project/alire/releases`. In this sandbox that request returns **HTTP 403** (reproduced live, see §6), which is consistent with an egress-proxy/allowlist restriction rather than an Alire-side outage.
- **`docs/certification/coverage-guide.md:315-319`** documents an `alire-project/setup-alire@v2` + `alr install gnatcov` CI recipe that does not correspond to anything in `ci.yml` (which uses `@v3` and never installs gnatcov) — aspirational/inconsistent documentation, not a real dependency.

## 5. Invariants and Conventions

- **Build-mode contract:** `ada/hale_orbital.gpr` external `BUILD_MODE` must be one of `debug|release|spark|deterministic` (`hale_orbital.gpr:13-14`); CI only exercises `debug`/`release` (`ci.yml:24-25`) — `spark` and `deterministic` modes are unexercised by CI (the latter backs ISS-024 determinism claims but is never actually built in the pipeline).
- **Warnings-as-errors:** `hale_orbital.gpr:30` sets `-gnatwe`, so any new warning in library code is a hard compile failure locally — a real, load-bearing gate, just not one visible in a green/red CI check today because the whole job is `continue-on-error`.
- **`Units` list must track `ada/src/*.ads`:** `ada/coverage.gpr:76-90` hardcodes 13 unit names; verified they match the current 13 `.ads` files 1:1. This is a manually-maintained invariant with no automated check — adding a 14th package without updating `coverage.gpr` would silently exclude it from coverage scope.
- **Which CI jobs actually gate a PR (verified, not assumed):**
  - `build-and-test` — **does not gate** (`continue-on-error: true`, `ci.yml:21`), and even locally its "Run tests" step (`run_tests.adb`) cannot fail on assertion failure (no `Set_Exit_Status`, see §3.7).
  - `spark-flow` — **does not gate** (`continue-on-error: true`, `ci.yml:56`); further, it's a no-op today since `gnatprove` is absent from the toolchain and the script degrades to a warning (`ci.yml:70-73`).
  - `python-oracle` — **does not gate**; no `continue-on-error` field, but the test step's own `|| echo "::warning..."` (`ci.yml:96`) masks any nonzero pytest exit code before the shell step returns.
  - `doc-lint` — **the only job that can actually fail the workflow**: unconditional `exit 1` on persona-narrative regression or missing required docs (`ci.yml:108-111,113-115`), not wrapped in `||` and no `continue-on-error`.
  - Net effect: today, a PR that breaks the Ada build, breaks every test, or fails SPARK flow analysis can still show all-green CI, provided the persona-narrative grep and the four required-doc existence checks pass.
- **`.claude/setup.sh` is intended to be idempotent and non-fatal** (comment at line 6; every top-level call in `main` is wrapped with `|| true`, lines 119-121) — but it still exits 1 overall due to a real bug (§6), which is masked by the `| tail -40` pipe in `settings.json:9` (pipeline exit status becomes `tail`'s, i.e. 0), so the SessionStart hook itself won't be reported as failed even though the script logs an error on its last line.
- **RTM/SRS/test-RTM requirement-ID schemes are not unified** (§3.4) — any tooling or reviewer assuming the RTM's `HLR-TB-*` IDs can be cross-referenced against the SRS/test-RTM's `HLR-1A-*` IDs will find no matches.
- **`docs/certification/level-b-roadmap.md`** Phase 1 tasks are all still checkbox `☐` (unchecked) — e.g. "Create coverage test driver → `test_driver_coverage.adb`" (`level-b-roadmap.md:80`) and "Add coverage merge script → `merge_coverage.sh`" (line 81) — even though both files already exist in the repo. The roadmap's completion tracking is stale relative to the actual file tree.
- **Inventory cross-check:** `docs/review/00-inventory.md:435-439` (§7.7) reports SRS/SDS/SCS/RTM/test-RTM sizes as "9,871 / 13,640 / 10,372 / 21,822 / 13,767 lines" — these numbers are actually the files' **byte sizes**, not line counts. Measured line counts are SRS.md=401, SDS.md=401, SCS.md=452, rtm.md=425, test-rtm.md=276 lines (`wc -l`, verified). The certification doc set is real and substantive but roughly 25-50x smaller than the Phase-1 inventory's "extraordinarily thorough" framing implies; worth a correction note for any agent citing those figures downstream.

## 6. MATRIX FLAGS

### Security observations

- **Toolchain bootstrap fetches and executes a remote binary archive over HTTPS with no checksum/signature verification.** `.claude/setup.sh:44` downloads `alr-2.0.2-bin-x86_64-linux.zip` from a GitHub Releases URL and, on success, `install -m 0755` the extracted `alr` binary straight to `${HOME}/.local/bin/alr` (line 68) with no hash pin, no GPG/sigstore check. In this sandbox the request is rejected with **HTTP 403** (reproduced live: `curl: (22) The requested URL returned error: 403`), so the install currently no-ops rather than silently trusting an unverified artifact — but the script has no integrity check even when the download *does* succeed, which is a supply-chain gap if this ever runs in a less-restricted network.
- **Confirmed unbound-variable bug causes the setup script to always exit 1** (`.claude/setup.sh`): `trap 'rm -rf "${tmp}"' RETURN` is registered inside `install_alire()` (line 41) using a `local tmp` (line 39). Bash `RETURN` traps are **not function-scoped** — once set, they fire on every subsequent function return in the process, including `install_toolchain`, `install_python_oracle`, and `main` itself. After `install_alire` returns, `tmp` goes out of scope; the next function return fires the stale trap and, under `set -euo pipefail` (line 12), `${tmp}` is unbound, aborting the script. Reproduced live:
  ```
  $ bash .claude/setup.sh
  ...
  [hale-setup] ready
  .claude/setup.sh: line 117: tmp: unbound variable
  $ echo $?
  1
  ```
  (line 117 is `main() {`; bash attributes the trap-firing error to the enclosing function's definition line, not the original `trap` call site at line 41). This failure is currently **masked** by `.claude/settings.json:9`'s `bash .claude/setup.sh 2>&1 | tail -40` — the pipeline's exit status is `tail`'s (0), not `setup.sh`'s (1) — so the SessionStart hook does not surface the script's true failure state to any exit-code-checking caller, only in the (truncated) log text.
- **No secrets or credentials found** in this domain's files (`alire.toml`, `ci.yml`, `setup.sh`, `merge_coverage.sh`) — consistent with `00-inventory.md` §6.3/§7.8.
- **CI trusts `pip install` from PyPI with no version pins beyond `>=`** (`python/three-body-extension/requirements.txt`, invoked at `ci.yml:86-89`) — floating dependency versions are a minor supply-chain/reproducibility concern for a DO-178C-flavored project, though this is shared with the `restricted-astrodynamics` domain and not unique to CI wiring.
- **`scripts/merge_coverage.sh` unquoted variable expansion** at `merge_coverage.sh:243` (`$TRACE_FILES` deliberately unquoted, `# shellcheck disable=SC2086` at line 236) is intentional (needed to pass multiple filenames as separate `gnatcov` arguments) but would mis-split any trace-file path containing whitespace; low risk in this build layout but worth flagging as filesystem-path handling.
- **Doc-lint job's grep-based safeguard is the only real gate** (`ci.yml:108`); it is a content-based regex check (`frodo|gandalf|hobbit|bilbo|sam-wise`) confined to `.claude` and `docs/plans` — it does not scan the full tree, so a persona-narrative regression placed elsewhere would not be caught by this job. Not a security issue per se, but it is the single enforcement point currently doing real work in this pipeline, worth knowing its blind spot.

### Quality observations

- **The certification-critical claim "CI validates" test results is false as currently wired.** `docs/certification/DO-178C-compliance-checklist.md:74` states `A-6.2 Results correct — COMPLETE — CI validates`. As shown in §3, the binary CI actually executes (`run_tests.adb`) never sets a nonzero exit status on test failure, and the 234 tests the test-RTM marks "✓ Complete" (`test-rtm.md:20-33`) are not built by the CI-facing `.gpr` project at all. This is the most significant finding in this domain review: **the automated pipeline cannot currently detect a broken build or a regressed algorithm**, undermining the DO-178C evidentiary claims that depend on "CI validates."
- **Dead/orphaned verification code:** `ada/tests/run_all_tests.adb` (388 lines, the only runner that both wires the full suite set *and* correctly propagates exit status via `CLI.Set_Exit_Status`, lines 382-386) is not referenced as `Main` by any `.gpr` file — it cannot be built via the documented workflow (`gprbuild -P ada/tests/hale_tests.gpr`). It appears to be superseded-but-not-deleted scaffolding from ISS-001 in `remaining_issues.csv:2` ("run_all_tests.adb comprehensive runner" listed as a delivered artifact of a `COMPLETED` issue).
- **Two disjoint requirement-ID schemes across SRS/RTM/test-RTM** (§3.4, §5) mean the RTM does not actually provide the "bidirectional traceability" (`rtm.md:13`) it claims against the SRS it should trace to. This is a structural defect in the certification evidence chain, not a documentation typo — every `HLR-TB-*` entry in `rtm.md` has no counterpart `HLR-TB-*` requirement in `SRS.md`, and vice versa for `HLR-1A-*`.
- **`docs/certification/level-b-roadmap.md`** task checkboxes are stale (all `☐` in Phase 1 despite artifacts existing — §5), which will mislead anyone using the roadmap as a status source of truth.
- **`docs/certification/coverage-guide.md` and `level-b-roadmap.md` both reference a `.github/workflows/coverage.yml` that does not exist** (§3.8, §4) — aspirational documentation presented as current process.
- **`docs/certification/coverage-guide.md:292,375` references `docs/certification/coverage-justification.md`** as the template target for uncovered-code justification; this file does not exist in `docs/certification/` (confirmed via directory listing) — the coverage-gap justification process described has no actual artifact yet.
- **CI comment/reality drift:** `ci.yml:14` claims "37 tests pass locally," but `run_tests.adb` (the file that comment describes) currently contains 64 `Run_Test` calls — the comment is stale relative to the file it documents (minor, but indicative of comments not being kept in sync with fast-moving test files).
- **`test_driver_coverage.adb`'s own pass/fail accounting is unreliable** (§2): `Results.Total_Tests` (line 39) is declared but never incremented (dead field), and `Results.Failed_Tests` only increments on an uncaught exception per *suite* (max 6 possible increments across potentially hundreds of assertions), not per failed assertion — so even the more complete coverage-oriented driver would report "All test suites completed successfully" (line 199) despite widespread assertion failures inside a suite, as long as nothing raises.
- **Inventory line-count discrepancy** (§5, last bullet) suggests downstream consumers of `00-inventory.md`'s certification-doc size figures should re-derive them rather than cite directly.
- **No test coverage of the CI/infrastructure layer itself** — there is no test that asserts `hale_tests.gpr`'s `Main` list matches the certification test-RTM's suite list, no test that a failing assertion actually turns the harness's exit code nonzero, and no CI job that runs `scripts/merge_coverage.sh` to catch coverage regressions. The verification infrastructure has no meta-verification.
- **Bus factor** (per `docs/review/10-history.md` §3): all of `docs/certification/`, `.github/workflows/ci.yml`, `.claude/setup.sh`, and `scripts/merge_coverage.sh` were authored by a single contributor (THOClabs) in one Phase-1 commit (`ae918db`); no second author has touched this domain's files. Given the number of internal inconsistencies found above, an independent second reviewer would likely be high-value here specifically (also a DO-178C process expectation — Level B requires review independence, `level-b-roadmap.md:20`).

---

## Cross-domain touchpoints (not analyzed in depth here)

- `ada/src/*` (dimensional-foundation, classical-astrodynamics, trajectory-optimization, restricted-astrodynamics domains) — this report treats `ada/tests/` purely as verification-infrastructure wiring, not per-algorithm correctness; the `Assert`/`Run_Test` framework and the algorithms it exercises belong to those other domain reports.
- `python/three-body-extension/` — the `python-oracle` CI job's target; CR3BP oracle completeness is out of scope here beyond the CI-wiring observation in §6.
- `docs/ROADMAP.md`, `docs/ARCHITECTURE.md` — referenced by `doc-lint`'s required-file check (`ci.yml:113`) but owned by other domains/chief-architect.
