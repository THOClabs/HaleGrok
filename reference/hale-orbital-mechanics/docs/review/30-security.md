# Security Audit (Phase 4, Cross-Cutting)

**Auditor:** L4 Security Auditor
**Date:** 2026-07-12
**Repository:** /home/user/hale-orbital-mechanics (commit 0345758, branch `claude/add-review-org-mda8xc`)
**Inputs consumed:** `docs/review/00-inventory.md`, `10-history.md`, all five `20-domain-*.md` reports (every "Security observations" flag cross-checked below).
**Method:** Read-only. Every analyst flag and every new finding was re-verified against the actual source before inclusion. Independent sweeps: secrets-pattern grep (repo-wide), injection/deserialization grep (Python + Ada `with`-clause audit), CI/setup-script trust-boundary review, dependency state (`pip list`; `pip-audit` unavailable in this container), filesystem/network hygiene in `.claude/setup.sh`, `.github/workflows/ci.yml`, `scripts/merge_coverage.sh`. One dynamic check was performed in an isolated scratchpad (bash `RETURN`-trap semantics repro); the repository itself was not modified or executed beyond that.

**Context for severity calibration:** this is a numerical library with no network service, no authentication, no user-facing input parser, and no secrets. Its real trust boundaries are (a) the CI/setup automation that produces the project's *assurance evidence* — critical for a DO-178C-track project whose main product is trust — and (b) numeric inputs crossing the public Ada API. Severities below reflect that framing.

**Finding counts:** Critical 0 · High 2 · Medium 3 · Low 6 · Info 5

---

## High

### H1. The verification pipeline is incapable of failing on a broken build or regressed algorithm

- **Locations:**
  - `.github/workflows/ci.yml:21` — `continue-on-error: true` on the `build-and-test` job
  - `.github/workflows/ci.yml:56` — `continue-on-error: true` on `spark-flow` (which is additionally a no-op: gnatprove absent, degrades to a warning at `ci.yml:70-73`)
  - `.github/workflows/ci.yml:96` — `pytest -x --tb=short || echo "::warning::..."` masks any nonzero pytest exit
  - `ada/tests/run_tests.adb` — the only test binary CI builds and runs (`ada/tests/hale_tests.gpr:11`, `ci.yml:44-47`) contains **no call to `Ada.Command_Line.Set_Exit_Status`** (repo-wide grep: only the never-built `run_all_tests.adb:383-385` and the coverage-only `test_driver_coverage.adb:273-275` set exit status). It prints pass/fail counts and always exits 0.
- **Evidence:** grep for `Set_Exit_Status` across `ada/tests/` returns zero hits in `run_tests.adb`; `ci.yml` verified line-by-line — the only steps with a live `exit 1` are in the `doc-lint` job (`ci.yml:108-115`), which checks persona-narrative regressions and four doc files' existence, nothing about code.
- **Why it matters:** for a certification-track library, the green CI check *is* the assurance signal, and `docs/certification/DO-178C-compliance-checklist.md:74` explicitly claims "A-6.2 Results correct — COMPLETE — CI validates." As wired, a PR that breaks the build, fails every test, or (maliciously or accidentally) regresses a trajectory algorithm still shows green. This is an integrity failure of the evidence chain, which is the closest thing this repository has to a security perimeter. It also means the two High/Critical numeric issues tracked in `docs/certification/compliance-issues.csv` have no automated regression net.
- **Smallest credible fix:** (1) add a failure counter check + `Ada.Command_Line.Set_Exit_Status (Failure)` at the end of `run_tests.adb` (the pattern already exists in `run_all_tests.adb:382-386`); (2) delete `continue-on-error: true` from `build-and-test`; (3) drop the `|| echo` on the pytest step (the periodic/manifold gaps it excuses are *untested modules*, not failing tests — the suite currently passes 49/49).
- **Cross-check:** confirms and escalates the certification-safety analyst's top flag (their §6 quality observation; escalated here because assurance-pipeline integrity is a security property for this project).

### H2. `Solve_Lambert` can return `Converged = True` with NaN/Inf velocities — in **every** build mode, not just release

- **Locations:** `ada/src/hale_orbital-lambert.adb:156, 161, 175, 187, 224, 228` (divisions by `C_Z` / `Sqrt (C_Z)`), `lambert.adb:236-237` (division by `G_Func` with no nonzero guard), `lambert.adb:187,228` (division by `1.0 - Z * C_Z`, unguarded). The only relevant contract is `Stumpff.C'Result >= 0.0` / `S'Result >= 0.0` (`ada/src/hale_orbital-stumpff.ads:37,57`) — `>= 0.0`, not `> 0.0`, and `C(z) → 0` as `z → +4π² = Z_High` (`lambert.adb:151`).
- **Evidence snippet (`lambert.adb:236-237`):**
  ```ada
  Result.V1 := (1.0 / G_Func) * (R2 - F_Func * R1);
  Result.V2 := (1.0 / G_Func) * (G_Dot * R2 - R1);
  ```
  with `G_Func := Dm * Sqrt (Y / Mu_Val)` (`lambert.adb:232`) and `Y >= 0.0` (zero permitted) as the only constraint.
- **Why it matters — and a correction to the analyst's mitigation claim:** this is tracked as **Critical/Open** `ISS-010` (`docs/certification/compliance-issues.csv:11`). The trajectory-optimization report asserted that debug/spark/deterministic modes "retain `-gnato` and would likely catch this." That is **not correct for floating point**: `-gnato` (`ada/hale_orbital.gpr:36,50,58`) governs arithmetic-overflow checking, and on IEEE GNAT targets `Long_Float'Machine_Overflows` is False — float division by zero yields ±Inf/NaN *silently, without `Constraint_Error`, in all four build modes*. No mode sets `-gnateF` (float-overflow validity checking; verified absent from `hale_orbital.gpr:16-65`), and `-fsignaling-nans` in `deterministic` mode (`hale_orbital.gpr:63`) does not trap quiet-NaN production from `0/0` or Inf from `x/0`. So the exposure is strictly worse than reported: a caller-supplied state that drives `C_Z`, `1 - Z*C_Z`, or `G_Func` to zero produces non-finite `V1`/`V2`/`A` fields alongside `Converged = True`, in *any* build, and nothing downstream checks finiteness.
- **Smallest credible fix:** in `Solve_Lambert`/`Solve_Lambert_Bounded`, guard the three denominators (`C_Z`, `1.0 - Z*C_Z`, `G_Func`) against `abs (...) < Small_Threshold` and return `Converged := False` on violation; alternatively (or additionally) a single post-solve finiteness gate using the `'Valid` attribute on `Result.V1/V2/A` before setting `Converged := True`.
- **Cross-check:** confirms the analyst's core flag (ISS-010), refutes their build-mode mitigation claim, escalates scope to all build modes.

---

## Medium

### M1. SessionStart bootstrap installs a remote binary with no integrity verification

- **Location:** `.claude/setup.sh:20` (URL constant), `:44-48` (curl/wget download), `:63-68` (`install -m 0755 "${found}" "${ALR_BIN}"`); auto-executed on every session via `.claude/settings.json:9`.
- **Evidence:** `curl -fsSL --retry 4 ... -o "${tmp}/alr.zip" "${ALIRE_RELEASE_URL}"` followed by unzip and direct install of whatever executable named `alr` is found in the archive (`find ... -name alr -perm -u+x | head -1`). No SHA-256 pin, no signature check.
- **Why it matters:** the URL is HTTPS and version-pinned, but a compromised release asset, a CDN/proxy MITM terminating TLS (this environment routes through a proxy CA), or a repointed tag would be installed and executed without detection — into the toolchain that *compiles the certified library*. Compiler/toolchain provenance is exactly the class of supply-chain risk DO-178C tool-qualification cares about. (Currently moot in this sandbox — the download 403s, reproduced by the certification analyst — but the script is designed to run wherever sessions start.)
- **Smallest credible fix:** add the known SHA-256 of `alr-2.0.2-bin-x86_64-linux.zip` as a constant and verify with `sha256sum -c` between download and unzip; abort install on mismatch.
- **Cross-check:** confirms the certification-safety analyst's flag.

### M2. CI workflow runs unpinned third-party code with default token permissions and persisted git credentials

- **Locations:** `.github/workflows/ci.yml` — no `permissions:` block anywhere in the file (verified full read, lines 1-116); `actions/checkout@v4` used at `ci.yml:27, 58, 80, 102` with default `persist-credentials: true`; the `python-oracle` job then installs **unpinned** PyPI packages (`pip install numpy scipy pytest`, `ci.yml:87`, plus floor-only `requirements.txt`, `ci.yml:88-89`) and executes them (`pytest`, `ci.yml:96`) in the same checkout.
- **Why it matters:** with `persist-credentials: true`, the `GITHUB_TOKEN` is written into `.git/config` in the workspace; any code executed later in the job — including a hypothetically compromised numpy/scipy/pytest release pulled at whatever-is-latest — can read it. Without a `permissions:` block, the token's scope falls back to the repository/organization default, which on longer-lived repos is read/write. This is the standard GitHub Actions least-privilege gap, made more relevant here by the fully floating dependency set.
- **Smallest credible fix:** add top-level `permissions: contents: read` to `ci.yml`; add `with: persist-credentials: false` to each checkout (no step in this workflow pushes); pin the Python install (see L6).
- **Cross-check:** the unpinned-pip half confirms the certification-safety analyst's flag; the missing-permissions-block and persisted-credentials halves are new findings from this audit.

### M3. Verification claims in shipped source headers and in the SPARK scope document are false in both directions

- **Locations and evidence:**
  - `ada/src/hale_orbital-vectors.ads:7` — "SPARK Status: This package is proven free of runtime errors." Body: `ada/src/hale_orbital-vectors.adb:8` — `SPARK_Mode => Off`.
  - `ada/src/hale_orbital-kepler.ads:10` — "Core solvers proven free of runtime errors." Body: `kepler.adb:13` — `Off`.
  - `ada/src/hale_orbital-stumpff.ads:11` — "formally verified." Body: `stumpff.adb:8` — `Off`.
  - `ada/src/hale_orbital-matrices.ads:7`, `twobody.ads:10` — "formally verifiable" framing; bodies `Off` (`matrices.adb:8`, `twobody.adb:10`).
  - `docs/certification/spark-scope.md:54-55` claims Vectors body = **On / Gold / "Fully proven"** and Matrices body = **On / Silver / "Proven"** — contradicted by both `.adb` files (`SPARK_Mode => Off`). `spark-scope.md:73` claims the Threebody body is **Off** — but `ada/src/threebody/hale_orbital-threebody.adb:8` is actually the *only* library body with `SPARK_Mode => On`. The scope document is wrong in both directions.
  - gnatprove has never run in any pipeline: `ci.yml:70-73` degrades to a warning when absent, and it is absent (Alire 2.0.2 has no gnatprove component).
- **Why it matters:** "proven free of runtime errors" is a safety claim consumers of a DO-178C-track library may rely on when skipping their own defensive checks. No machine proof has ever been produced, and the project's own authoritative scope table cannot be trusted to say which bodies are even *in* scope. This is a false-assurance defect, the documentation analogue of a forged test result.
- **Smallest credible fix:** one editing pass: replace all "proven/verified" spec-header claims with "contracts defined; body proof pending (Bronze — see docs/certification/spark-scope.md)", and correct `spark-scope.md` rows 54-55 and 73 to match the actual `SPARK_Mode` aspects.
- **Cross-check:** confirms the dimensional-foundation analyst's flag (their "most notable finding") and the classical-astrodynamics analyst's flag; the two `spark-scope.md` internal contradictions (Vectors/Matrices "On/Gold/Silver", Threebody "Off") are new evidence found by this audit.

---

## Low

### L1. Setup script always exits 1 via a leaked `RETURN` trap, and the SessionStart hook masks the failure

- **Location:** `.claude/setup.sh:39-41` (`local tmp; ... trap 'rm -rf "${tmp}"' RETURN` inside `install_alire`), masked by `.claude/settings.json:9` (`bash .claude/setup.sh 2>&1 | tail -40` — pipeline exit status is `tail`'s, i.e. 0).
- **Evidence:** independently reproduced in an isolated scratchpad script (not by running setup.sh): a `RETURN` trap set inside one function fires on every subsequent function return; with `set -euo pipefail` and `tmp` out of scope, the script aborts with `tmp: unbound variable`, exit 1 — exactly matching the certification analyst's live capture.
- **Why it matters:** the bootstrap trust boundary cannot report failure. Any *real* future failure of this script (including a failed integrity check once M1 is fixed) is invisible to exit-code-checking callers.
- **Smallest credible fix:** `trap 'rm -rf "${tmp:-}"; trap - RETURN' RETURN` (self-clearing, unset-safe); optionally remove `| tail -40` in favor of a bounded log file so exit status propagates.
- **Cross-check:** confirms the certification-safety analyst's flag, with independent reproduction.

### L2. `merge_coverage.sh`: user-supplied output dir feeds `rm -rf`, and trace-file list is unquoted

- **Location:** `scripts/merge_coverage.sh:89-91` (`-o|--output` sets `REPORT_DIR` verbatim) → `:136-142` (`--clean` executes `rm -rf "$REPORT_DIR"/*`); `:224` (`TRACE_FILES=$(find ...)`) → `:236-243` (deliberately unquoted `$TRACE_FILES`, shellcheck-suppressed).
- **Why it matters:** `./scripts/merge_coverage.sh -c -o /some/important/dir` deletes that directory's contents with no confinement check — an operator footgun, not an attack vector (developer-invoked, developer-supplied argument). The unquoted expansion mis-splits any trace path containing whitespace; low risk in this layout, real risk if `TRACE_DIR` is ever relocated.
- **Smallest credible fix:** refuse `--clean` unless `REPORT_DIR` is under `$PROJECT_ROOT` (`case "$REPORT_DIR" in "$PROJECT_ROOT"/*) ... esac`); replace the string list with `mapfile -t TRACE_FILES < <(find ...)` and expand `"${TRACE_FILES[@]}"`.
- **Cross-check:** confirms the certification-safety analyst's unquoted-variable flag; the `rm -rf` path-confinement point is new.

### L3. `Solve_Lambert` silently accepts degenerate (collinear) geometry, contradicting its own spec document

- **Location:** `ada/src/hale_orbital-lambert.adb:105-133` — `Cos_Dnu` clamped, transfer plane chosen by an arbitrary `Cross_Z >= 0.0` tie-break; the existing detector `Is_Degenerate_Transfer` (`lambert.adb:622-644`) is called by `Solve_Lambert_Multi` (`lambert.adb:395`) but never by `Solve_Lambert`. `docs/specs/05-lambert.md:40,57` states a ~180° transfer "raises `Invalid_Orbit`" — it does not.
- **Why it matters:** input-validation gap at the public API: antiparallel `R1`/`R2` (a physically ill-posed problem) returns `Converged = True` with an arbitrary transfer plane instead of failing loudly. Any caller treating `Converged` as a correctness signal is misled.
- **Smallest credible fix:** call `Is_Degenerate_Transfer (R1, R2)` at `Solve_Lambert` entry and either raise `Invalid_Orbit` (matching the spec doc) or return `Converged := False`.
- **Cross-check:** confirms the trajectory-optimization analyst's flag (verified: detector exists, call site absent).

### L4. Inconsistent precondition coverage on the public numeric API; release mode additionally suppresses language-defined checks

- **Location:** `ada/src/hale_orbital-twobody.ads:127-148` — `Semi_Latus_Rectum`, `Periapsis_Distance`, `Apoapsis_Distance` (spec), `Radius_At_True_Anomaly` carry only `Global => null`, no `Pre` on eccentricity, while sibling functions in the same package and in `Elements` validate ranges and raise `Invalid_Orbit`. Same pattern at `lambert.ads:118-137` (`Get_Transfer_Elements`, delta-V helpers, per the domain report). Release mode adds `-gnatp` (`ada/hale_orbital.gpr:44`), suppressing language-defined checks (range/index/overflow) there.
- **Why it matters:** callers cannot rely on a uniform validation contract at the trust boundary — some functions reject unphysical inputs, adjacent ones return silently-wrong values. Note the important correction recorded in "Cleared" below: `Pre`/`Post` contracts are **not** compiled out in release (`-gnata` is common to all modes, `hale_orbital.gpr:28`, and `-gnatp` does not suppress assertion-policy checks), so the fix is cheap and effective in every mode.
- **Smallest credible fix:** add `Pre => E >= 0.0 and E < 1.0 - Parabolic_Threshold` (or the appropriate conic-specific range) to the four unguarded `Twobody` geometry functions and the `Lambert` helper functions.
- **Cross-check:** confirms the classical-astrodynamics analyst's flag; severity tempered by the release-mode correction.

### L5. GitHub Actions pinned by mutable tag, not commit SHA

- **Location:** `.github/workflows/ci.yml:27,58,80,102` (`actions/checkout@v4`), `:30,61` (`alire-project/setup-alire@v3`), `:81` (`actions/setup-python@v5`).
- **Why it matters:** tags are mutable; a compromised action repository can retarget `v3`/`v4` at malicious code that runs with the workflow's token (compounding M2). `alire-project/setup-alire` is a comparatively low-profile third-party action — the least-scrutinized link in this chain.
- **Smallest credible fix:** pin each `uses:` to a full commit SHA with a trailing version comment (Dependabot can keep them fresh).
- **Cross-check:** new finding (inventory noted the actions in passing; no analyst assessed pinning).

### L6. Python oracle dependencies are floor-only with no lockfile, and the package is not installable

- **Location:** `python/requirements.txt` and `python/three-body-extension/requirements.txt` (all `>=`, no ceilings, no hashes — verified); no `pyproject.toml`/`setup.py` anywhere; six files bootstrap imports via `sys.path.insert(0, ...'src')` (`tests/conftest.py:17`, `tests/test_*.py:10`, `examples/*.py:13-14`).
- **Why it matters:** CI resolves whatever PyPI serves that day (currently numpy 2.4.6 / scipy 1.17.1 / pytest 9.1.1 locally — all far above the floors). For an *oracle whose job is to produce reference truth*, non-reproducible dependency resolution is an evidence-integrity problem as much as a supply-chain one; and the `sys.path` pattern means whichever `threebody` shadows the path first wins.
- **Smallest credible fix:** add a `constraints.txt` (or hash-pinned `requirements.lock`) used by `ci.yml:88-89`, and a minimal `pyproject.toml` so tests can `pip install -e .` instead of path injection.
- **Cross-check:** confirms the restricted-astrodynamics and certification-safety analysts' flags.

---

## Info

### I1. No secrets in the repository (independent sweep, confirms inventory §6.3)

Repo-wide case-insensitive grep for credential patterns (`api[_-]key`, `secret`, `passwd/password`, `token`, `credential`, PEM headers, AWS `AKIA...`, GitHub `ghp_...`, Slack `xox...`) returned only documentation self-references (review reports, agent definitions) and one archived persona file containing the word "Secretly". No `.env`, `.pem`, `.key`, keystore, or credential files exist (glob verified). `alire.toml` carries only public metadata.

### I2. No injection or deserialization surface exists; the "CSV ingestion" trust boundary is empty

- Python: zero occurrences of `eval`, `exec`, `pickle`, `__import__`, `subprocess`, `os.system`, `os.popen`, `yaml.load`, `shell=True`, or network/file I/O (`open(`, `urlopen`, `requests.`, `np.load/save`, `savefig`, `read_csv`) in `python/` library, test, or example code (verified grep; the sole `eval` hit is the word "evaluated" in a docstring).
- Ada: `Ada.Text_IO`/`Ada.Command_Line` appear only under `ada/tests/` and `ada/examples/`; no library unit under `ada/src/` withs any I/O, environment, socket, or process package.
- The three `.csv` files in the repo (`remaining_issues.csv`, `docs/certification/compliance-issues.csv`, test RTM data) are human-maintained tracking sheets; **no code anywhere parses CSV**, so the "reference-data ingestion" boundary anticipated by the inventory does not yet exist to audit.

### I3. The only CI job that can fail has a scope blind spot

`doc-lint`'s persona-regression grep (`ci.yml:108`) scans only `.claude` and `docs/plans`; a regression placed anywhere else passes. Worth knowing because per H1 this is currently the *only* enforcement point in the pipeline. Fix trivially by widening the `find` path set once H1 restores the other gates.

### I4. `Analyze_Floquet` NaN behavior is fail-conservative for its main verdict, but 4 of 6 returned multipliers are not eigenvalues

Verified `ada/src/threebody/hale_orbital-threebody.adb:719-793`: a NaN-contaminated monodromy matrix propagates NaN through the power iteration (the `Norm < 1.0e-15` early-exit at `:767` is False for NaN) into `Max_Multiplier`, and `Is_Stable := Result.Max_Multiplier <= 1.0 + 1.0e-6` (`:790`) evaluates **False** for NaN — i.e., the headline stability verdict fails safe. However `Multipliers(3..6)` remain raw diagonal entries (`:740-742`, self-documented simplification) and `Stability_Index` can be NaN, with no validity flag on `Floquet_Result`. This refines (partially confirms) the restricted-astrodynamics analyst's flag: the "superficially valid garbage" risk is real for the multiplier array, not for `Is_Stable`. Smallest fix: add a `Valid : Boolean` field set via `'Valid` checks on the monodromy inputs.

### I5. Dependency audit tooling and environment state

`pip-audit`/`osv-scanner`/`cargo audit` are unavailable in this container. Manual review of installed versions (numpy 2.4.6, scipy 1.17.1, pytest 9.1.1, pytest-cov 7.1.0, matplotlib 3.11.0): no known CVEs for these versions to this auditor's knowledge. The container's `setuptools 68.1.2` predates the fixes for CVE-2024-6345 (RCE in `package_index`, fixed in 70.0) and CVE-2025-47273 (path traversal, fixed in 78.1.1) — but setuptools is an environment tool, not a repo-declared dependency, and the vulnerable code paths (`easy_install`/`package_index`) are not exercised by this project. No Ada dependencies are declared at all (`alire.toml` has no `[[depends-on]]`), so there is no Alire dependency risk beyond the toolchain itself (see M1); note also there is no `alire.lock`, so even toolchain resolution is unpinned (consistent with the certification analyst's observation).

---

## Cleared — analyst flags investigated and dismissed (or corrected)

| # | Flag (source report) | Verdict | Reason |
|---|---|---|---|
| C1 | "Pre/Post contracts are only enforced in debug/spark builds and are compiled out in release" (dimensional-foundation §6; restricted-astrodynamics §6; rooted in inventory §4.1 "checks suppressed") | **Refuted as stated** | `-gnata` is in `Common_Switches` applied to *all four* build modes (`ada/hale_orbital.gpr:28`). Release adds `-gnatp` (`:44`), which per GNAT semantics suppresses *language-defined* checks (range/index/overflow) but does not disable assertion-policy-controlled `Pre`/`Post`/`Assert` enabled by `-gnata`. Contracts remain live in release. The residual truth (language-defined checks off in release; no float-overflow trapping in any mode) is captured in L4 and H2. The trajectory-optimization report (§5, "Build-mode contract enforcement") had this right. |
| C2 | "debug/spark/deterministic retain `-gnato` and would likely catch the Lambert division blow-up" (trajectory-optimization §Security 1) | **Refuted — in the unsafe direction; escalated into H2** | `-gnato` governs arithmetic-overflow checking; on IEEE GNAT targets `Long_Float'Machine_Overflows` is False, so float `x/0.0` yields Inf/NaN silently in every mode. No mode sets `-gnateF`. The vulnerability is broader than flagged, not narrower. |
| C3 | "No auth, network, secrets, or deserialization surface" in the four numeric domains (all four Ada-domain reports) | **Confirmed benign** | Independent sweep (I1, I2): no I/O `with`-clauses in any `ada/src/` unit; no dangerous constructs or I/O in `python/`; no secrets patterns repo-wide. |
| C4 | "No DoS / unbounded-iteration surface; all solvers bounded by Max_Iter" (classical-astrodynamics §Security 4) | **Confirmed benign** | Spot-verified in the highest-risk loop: `lambert.adb:213-218` hard-exits with `Converged := False` at `Max_Iter = 100`; Kepler solvers carry the same pattern per two independent domain reports. No recursion anywhere in `ada/src/`. |
| C5 | "Python oracle has no exposed attack surface (no CLI on untrusted files, no pickle/yaml/eval, no subprocess)" (restricted-astrodynamics §Security) | **Confirmed benign** | Verified by grep (I2); additionally no file or network I/O at all in oracle library code. |
| C6 | "CSV reference-data ingestion" as a trust boundary (inventory §Domain 4, task brief) | **Dismissed — surface does not exist** | No code in the repository reads or parses any CSV; the cross-validation CSV pipeline is aspirational (confirmed by the restricted-astrodynamics report and re-verified: the only CSVs are tracking spreadsheets). Nothing to audit until Phase 7 builds it — at which point schema validation should be designed in. |
| C7 | `sys.path.insert` in tests/examples "not itself a vulnerability" (restricted-astrodynamics §Security) | **Confirmed — not a vulnerability** | Paths are derived from `__file__`, not from environment or user input; no privilege boundary crossed. Retained only as the packaging-reproducibility component of L6. |
| C8 | `.claude/` agent/command definitions as a possible instruction-injection vector (own sweep, not analyst-flagged) | **Dismissed** | All eight files read: small (20-25 line) role definitions and an orchestration command; review organization is explicitly read-only toward source; no hooks beyond the SessionStart entry already audited (M1/L1); `.claude/scheduled_tasks.lock` is an untracked runtime artifact, not repository content. |
| C9 | "Doc-lint grep safeguard is the only real gate and scans a limited path set" (certification-safety §Security) | **Confirmed, held at Info** | Verified `ci.yml:108`; recorded as I3 rather than a ranked finding — it is a completeness gap in a hygiene check, not an exposure. |

---

**Most important single takeaway:** this repository's genuine attack/failure surface is not its algorithms' inputs — it is the *assurance machinery around them*. H1 (a CI pipeline that cannot fail), M3 (source headers and the SPARK scope table asserting proofs that were never run), and H2 (a solver that reports success while returning non-finite trajectories in every build mode) together mean that today, neither a human reading the code's own claims nor a machine reading CI status can distinguish a correct build of this library from a broken or tampered one. All three are cheap to fix relative to their weight.
