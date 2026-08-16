#!/bin/bash
#===============================================================================
# HALE Orbital Mechanics - Coverage Merge Script
#===============================================================================
# Merges multiple coverage runs into a single consolidated report.
# DO-178C Level B: Statement + Decision Coverage
#
# Reference: docs/certification/level-b-roadmap.md Phase 1.2
# RTM: NFR-COV-002 (Coverage Merging)
#===============================================================================

set -e  # Exit on error

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADA_DIR="$PROJECT_ROOT/ada"
COVERAGE_DIR="$ADA_DIR/coverage"
TRACE_DIR="$COVERAGE_DIR/traces"
REPORT_DIR="$COVERAGE_DIR/reports"

# Coverage level (default: stmt+decision for Level B)
COVERAGE_LEVEL="${COVERAGE_LEVEL:-stmt+decision}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#===============================================================================
# Helper Functions
#===============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Merge coverage traces and generate consolidated reports.

Options:
    -l, --level LEVEL    Coverage level (stmt, stmt+decision, stmt+mcdc)
                         Default: stmt+decision (Level B)
    -o, --output DIR     Output directory for reports
                         Default: ada/coverage/reports
    -c, --clean          Clean existing coverage data before running
    -h, --help           Show this help message

Coverage Levels:
    stmt           Statement coverage only (Level C)
    stmt+decision  Statement + Decision coverage (Level B)
    stmt+mcdc      Statement + MC/DC coverage (Level A)

Examples:
    $(basename "$0")                    # Standard Level B coverage
    $(basename "$0") -l stmt            # Level C coverage only
    $(basename "$0") -c -l stmt+mcdc    # Clean and run Level A

DO-178C Compliance:
    Level C requires 100% statement coverage
    Level B requires 100% statement + decision coverage
    Level A requires 100% statement + MC/DC coverage
EOF
}

#===============================================================================
# Parse Arguments
#===============================================================================

CLEAN_FIRST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--level)
            COVERAGE_LEVEL="$2"
            shift 2
            ;;
        -o|--output)
            REPORT_DIR="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_FIRST=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

#===============================================================================
# Validate Coverage Level
#===============================================================================

case "$COVERAGE_LEVEL" in
    stmt|stmt+decision|stmt+mcdc)
        log_info "Coverage level: $COVERAGE_LEVEL"
        ;;
    *)
        log_error "Invalid coverage level: $COVERAGE_LEVEL"
        log_error "Valid options: stmt, stmt+decision, stmt+mcdc"
        exit 1
        ;;
esac

#===============================================================================
# Setup Directories
#===============================================================================

setup_directories() {
    log_info "Setting up coverage directories..."

    # --clean refuses to wipe any pre-existing directory that a previous run
    # of this script did not mark as its own (protects against
    # `-c -o <some-dir>` recursively deleting unrelated user data).
    if [ "$CLEAN_FIRST" = true ]; then
        for dir in "$TRACE_DIR" "$REPORT_DIR"; do
            if [ -d "$dir" ] && [ ! -f "$dir/.merge_coverage_owned" ]; then
                log_error "--clean refused: $dir exists but was not created by this script"
                exit 1
            fi
        done
        log_info "Cleaning existing coverage data..."
        rm -rf "$TRACE_DIR" "$REPORT_DIR"
    fi

    mkdir -p "$TRACE_DIR"
    mkdir -p "$REPORT_DIR/html"
    mkdir -p "$REPORT_DIR/xml"
    touch "$TRACE_DIR/.merge_coverage_owned" "$REPORT_DIR/.merge_coverage_owned"
}

#===============================================================================
# Instrument Source Code
#===============================================================================

instrument_source() {
    log_info "Instrumenting source code for coverage..."

    cd "$ADA_DIR"

    # Check if gnatcov is available
    if ! command -v gnatcov &> /dev/null; then
        log_error "gnatcov not found. Please install GNATcoverage."
        exit 1
    fi

    # Instrument the project
    gnatcov instrument -P coverage.gpr \
        --level="$COVERAGE_LEVEL" \
        --dump-trigger=atexit \
        --dump-filename-prefix="$TRACE_DIR/trace"

    log_info "Instrumentation complete."
}

#===============================================================================
# Build Instrumented Code
#===============================================================================

build_instrumented() {
    log_info "Building instrumented test driver..."

    cd "$ADA_DIR"

    gprbuild -P coverage.gpr -p \
        --src-subdirs=gnatcov-instr \
        --implicit-with=gnatcov_rts_full

    log_info "Build complete."
}

#===============================================================================
# Run Tests with Coverage
#===============================================================================

run_tests() {
    log_info "Running tests with coverage instrumentation..."

    cd "$ADA_DIR"

    # Run all test suites
    SUITES=("vallado" "edge" "negative" "exceptions" "boundaries" "periodic")

    for suite in "${SUITES[@]}"; do
        log_info "Running suite: $suite"

        # Run the test suite
        ./bin/test_driver_coverage --suite="$suite" || {
            log_warn "Suite $suite had failures, continuing..."
        }

        # Move trace file to unique name
        if [ -f "$TRACE_DIR/trace.srctrace" ]; then
            mv "$TRACE_DIR/trace.srctrace" "$TRACE_DIR/trace_${suite}.srctrace"
        fi
    done

    log_info "Test execution complete."
}

#===============================================================================
# Merge Coverage Traces
#===============================================================================

merge_traces() {
    log_info "Merging coverage traces..."

    cd "$ADA_DIR"

    # Find all trace files (array-safe: filenames with spaces survive)
    local trace_files=()
    while IFS= read -r -d '' f; do
        trace_files+=("$f")
    done < <(find "$TRACE_DIR" -name "*.srctrace" -type f -print0)

    if [ "${#trace_files[@]}" -eq 0 ]; then
        log_error "No trace files found in $TRACE_DIR"
        exit 1
    fi

    log_info "Found ${#trace_files[@]} trace files to merge."

    # Generate consolidated coverage report
    gnatcov coverage -P coverage.gpr \
        --level="$COVERAGE_LEVEL" \
        --annotate=xcov+ \
        --annotate=html+ \
        --annotate=cobertura \
        --output-dir="$REPORT_DIR/html" \
        "${trace_files[@]}"

    # Move cobertura XML to xml directory
    if [ -f "$REPORT_DIR/html/cobertura.xml" ]; then
        mv "$REPORT_DIR/html/cobertura.xml" "$REPORT_DIR/xml/coverage.xml"
    fi

    log_info "Coverage merge complete."
}

#===============================================================================
# Generate Summary Report
#===============================================================================

generate_summary() {
    log_info "Generating coverage summary..."

    SUMMARY_FILE="$REPORT_DIR/coverage-summary.txt"

    cat > "$SUMMARY_FILE" << EOF
===============================================================================
HALE Orbital Mechanics - Coverage Summary Report
===============================================================================
Date:           $(date -Iseconds)
Coverage Level: $COVERAGE_LEVEL
DO-178C DAL:    $(case "$COVERAGE_LEVEL" in
                    stmt) echo "Level C" ;;
                    stmt+decision) echo "Level B" ;;
                    stmt+mcdc) echo "Level A" ;;
                 esac)

===============================================================================
Coverage Reports Generated:
===============================================================================
HTML Report:    $REPORT_DIR/html/index.html
XML Report:     $REPORT_DIR/xml/coverage.xml
XCov Report:    $REPORT_DIR/html/*.xcov

===============================================================================
Units Covered:
===============================================================================
- hale_orbital (root package)
- hale_orbital.types
- hale_orbital.constants
- hale_orbital.vectors
- hale_orbital.matrices
- hale_orbital.elements
- hale_orbital.kepler
- hale_orbital.stumpff
- hale_orbital.twobody
- hale_orbital.lambert
- hale_orbital.propagation
- hale_orbital.maneuvers
- hale_orbital.threebody
- hale_orbital.interplanetary

===============================================================================
DO-178C Compliance Notes:
===============================================================================
- Statement coverage: Required for all DALs (C, B, A)
- Decision coverage: Required for DAL B and A
- MC/DC coverage: Required for DAL A only

All uncovered code must be justified with rationale documented in:
  docs/certification/coverage-justification.md

===============================================================================
EOF

    log_info "Summary written to: $SUMMARY_FILE"
    cat "$SUMMARY_FILE"
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
    log_info "HALE Orbital Mechanics - Coverage Merge Script"
    log_info "=============================================="

    setup_directories
    instrument_source
    build_instrumented
    run_tests
    merge_traces
    generate_summary

    log_info "=============================================="
    log_info "Coverage analysis complete!"
    log_info "View report: $REPORT_DIR/html/index.html"
}

# Run main function
main
