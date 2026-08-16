#!/usr/bin/env bash
# HALE Orbital Mechanics — toolchain bootstrap.
#
# Runs on Claude Code SessionStart in the remote-execution container.
# Idempotent: safe to re-run.  Tries to install Alire + GNAT + GNATprove via
# the most reliable available source; falls back to the system package
# manager if Alire's install scripts are unavailable.
#
# Output is captured into the session log; long-running tail-able output is
# trimmed in settings.json (`tail -40`).

set -euo pipefail

# ----- Helpers ---------------------------------------------------------------

have() { command -v "$1" >/dev/null 2>&1; }

note() { printf '[hale-setup] %s\n' "$*"; }

ALIRE_RELEASE_URL="https://github.com/alire-project/alire/releases/download/v2.0.2/alr-2.0.2-bin-x86_64-linux.zip"
# Upstream publishes no checksum for this asset (verified against the GitHub
# release API: digest=null, no .sha256 assets).  If you compute one on a
# trusted network (`sha256sum alr-2.0.2-bin-x86_64-linux.zip`), set it here
# and it will be enforced.  Until then the download is verified by TLS to a
# pinned URL plus a version assertion on the extracted binary.
ALIRE_SHA256=""
ALIRE_INSTALL_DIR="${HOME}/.local/share/alire"
ALR_BIN="${HOME}/.local/bin/alr"

mkdir -p "${HOME}/.local/bin"
case ":${PATH}:" in
   *":${HOME}/.local/bin:"*) ;;
   *) export PATH="${HOME}/.local/bin:${PATH}" ;;
esac

# ----- Alire ----------------------------------------------------------------

install_alire() {
   if have alr; then
      note "alr already on PATH: $(alr --version | head -1)"
      return 0
   fi

   note "installing alr 2.0.2 from upstream release tarball"
   local tmp
   tmp="$(mktemp -d)"
   # Self-clearing trap: without `trap - RETURN` the handler leaks to every
   # subsequent function return, where the (long gone) local ${tmp} is unset
   # and `set -u` aborts the whole script with "tmp: unbound variable".
   trap 'rm -rf "${tmp:-}"; trap - RETURN' RETURN

   if have curl; then
      curl -fsSL --retry 4 --retry-delay 2 -o "${tmp}/alr.zip" "${ALIRE_RELEASE_URL}" \
         || { note "curl download failed; skipping alr install"; return 1; }
   elif have wget; then
      wget -q --tries=4 --waitretry=2 -O "${tmp}/alr.zip" "${ALIRE_RELEASE_URL}" \
         || { note "wget download failed; skipping alr install"; return 1; }
   else
      note "neither curl nor wget available; skipping alr install"
      return 1
   fi

   if [[ -n "${ALIRE_SHA256}" ]]; then
      if ! printf '%s  %s\n' "${ALIRE_SHA256}" "${tmp}/alr.zip" | sha256sum -c - >/dev/null 2>&1; then
         note "alr.zip SHA-256 mismatch; refusing to install"
         return 1
      fi
      note "alr.zip SHA-256 verified"
   fi

   if ! have unzip; then
      note "unzip missing; trying python -m zipfile"
      python3 -m zipfile -e "${tmp}/alr.zip" "${tmp}/extract" \
         || { note "python unzip failed; skipping alr install"; return 1; }
   else
      unzip -q "${tmp}/alr.zip" -d "${tmp}/extract"
   fi

   local found
   found="$(find "${tmp}/extract" -type f -name alr -perm -u+x | head -1 || true)"
   if [[ -z "${found}" ]]; then
      note "alr binary not found in archive; skipping"
      return 1
   fi
   if ! "${found}" --version 2>/dev/null | grep -q "2\.0\.2"; then
      note "extracted alr does not report version 2.0.2; refusing to install"
      return 1
   fi
   install -m 0755 "${found}" "${ALR_BIN}"
   note "alr installed: $(${ALR_BIN} --version | head -1)"
}

# ----- GNAT toolchain via Alire ---------------------------------------------

install_toolchain() {
   if ! have alr; then
      note "alr unavailable; falling back to Ubuntu-archive GNAT"
      install_toolchain_apt
      return 0
   fi

   note "selecting gnat_native + gprbuild via alr"
   alr -n toolchain --select gnat_native gprbuild 2>&1 | tail -5 || true

   # Put Alire-installed toolchain binaries on PATH for this session.
   local toolchain_root="${HOME}/.local/share/alire/toolchains"
   if [[ -d "${toolchain_root}" ]]; then
      while IFS= read -r bindir; do
         case ":${PATH}:" in
            *":${bindir}:"*) ;;
            *) export PATH="${bindir}:${PATH}" ;;
         esac
      done < <(find "${toolchain_root}" -mindepth 2 -maxdepth 2 -type d -name bin)
   fi

   # gnatprove is not a toolchain component in Alire 2.0.2 — it's only
   # available via AdaCore SPARK Pro or the GNAT Community installer.
   # Phase 10 (SPARK proof bring-up) will wire it in; until then, leave
   # gnatprove absent on container starts so the summary is honest.
}

# Fallback: GNAT 14 + gprbuild from the Ubuntu archive (works even when the
# Alire release download is blocked by an egress proxy).  Same compiler
# generation as CI's gnat_native 14.2.1.
install_toolchain_apt() {
   if have gnat && have gprbuild; then
      note "gnat/gprbuild already present: $(gnat --version 2>/dev/null | head -1)"
      return 0
   fi
   if ! have apt-get; then
      note "apt-get unavailable; no toolchain fallback possible"
      return 0
   fi
   note "installing gnat-14 + gprbuild via apt (may take a minute)"
   if ! apt-get install -y -q gnat-14 gprbuild >/dev/null 2>&1; then
      note "apt install failed (offline archive or no privileges); skipping"
      return 0
   fi
   local t
   for t in gnat gnatbind gnatchop gnatclean gnatkr gnatlink gnatls gnatmake gnatname gnatprep; do
      [[ -e "/usr/bin/${t}-14" ]] && ln -sf "/usr/bin/${t}-14" "/usr/local/bin/${t}"
      [[ -e "/usr/bin/x86_64-linux-gnu-${t}-14" ]] \
         && ln -sf "/usr/bin/x86_64-linux-gnu-${t}-14" "/usr/local/bin/x86_64-linux-gnu-${t}"
   done
   note "gnat toolchain ready: $(gnat --version 2>/dev/null | head -1)"
}

# ----- Python validation oracle dependencies --------------------------------

install_python_oracle() {
   if ! [[ -f python/three-body-extension/requirements.txt ]]; then
      return 0
   fi
   if ! have python3; then
      note "python3 missing; skipping oracle deps"
      return 0
   fi
   note "installing Python three-body oracle dependencies"
   python3 -m pip install --quiet --user \
      -r python/three-body-extension/requirements.txt 2>&1 | tail -5 || true
}

# ----- Main ------------------------------------------------------------------

main() {
   note "bootstrapping HALE toolchain"
   install_alire || true
   install_toolchain || true
   install_python_oracle || true

   note "summary:"
   for cmd in alr gnat gprbuild gnatprove gnatcov python3; do
      if have "${cmd}"; then
         printf '  %-12s %s\n' "${cmd}" "$(command -v "${cmd}")"
      else
         printf '  %-12s (not installed)\n' "${cmd}"
      fi
   done
   note "ready"
}

main "$@"
