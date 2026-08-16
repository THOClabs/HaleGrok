# Agent Collaboration Protocol

## Meeting Record: January 2026

### Participants
- **Jean Ichbiah** - Original Ada Designer (Architecture Lead)
- **Tucker Taft** - Ada Evolution Architect (Modern Features Lead)
- **John Barnes** - Ada Educator (Documentation Lead)
- **Robert Dewar** - GNAT Architect (Implementation Lead)
- **Benjamin Brosgol** - Safety-Critical Expert (Certification Lead)

---

## Consensus: Unified Agent Instructions Format

After extensive discussion, we have agreed on a unified format for agent instructions that combines our expertise with Anthropic's principles.

### Core Instruction Structure

Each agent persona file follows this structure:

1. **Founding Era Identity** - Historical context from 1977-1983
2. **Core Philosophy** - Guiding principles with quotes
3. **Technical Contributions** - Domain-specific expertise with code examples
4. **Time Capsule** - Evolution through Ada 83 → 95 → 2005 → 2012 → 2022
5. **Modern Integration** - Anthropic HHH principles alignment
6. **Agent Instructions** - Code review perspective and focus areas
7. **Voice and Communication Style** - How the agent communicates
8. **Collaboration Protocol** - How to work with other agents
9. **Application to Orbital Mechanics** - Specific guidance for this project

### Anthropic Integration Points

We unanimously agreed to integrate Anthropic's principles:

| Ada Principle | Anthropic Parallel |
|--------------|-------------------|
| Strong typing | Input validation |
| Contracts (Pre/Post) | Constitutional AI principles |
| Exception handling | Error recovery mechanisms |
| SPARK verification | Formal safety proofs |
| Certification | Deployment review |

---

## Consensus: Project Folder Structure

After reviewing the current disorganized structure, we propose the following reorganization:

### Approved Structure

```
hale-orbital-mechanics/
├── .claude/
│   ├── personas/                 # Expert agent files
│   │   ├── jean-ichbiah.md
│   │   ├── tucker-taft.md
│   │   ├── john-barnes.md
│   │   ├── robert-dewar.md
│   │   ├── benjamin-brosgol.md
│   │   ├── EXPERT_RECOMMENDATIONS.md
│   │   └── README.md
│   ├── AGENT_COLLABORATION_PROTOCOL.md
│   └── PROJECT_REGISTERS.md
│
├── ada/                          # Ada implementation (PRIMARY)
│   ├── src/                      # Source code
│   │   ├── hale_orbital.ads/adb
│   │   ├── hale_orbital-types.ads
│   │   ├── hale_orbital-constants.ads
│   │   ├── hale_orbital-vectors.ads/adb
│   │   ├── hale_orbital-matrices.ads/adb
│   │   ├── hale_orbital-twobody.ads/adb
│   │   ├── hale_orbital-elements.ads/adb
│   │   ├── hale_orbital-kepler.ads/adb
│   │   ├── hale_orbital-lambert.ads/adb
│   │   ├── hale_orbital-maneuvers.ads/adb
│   │   └── threebody/            # Three-body problem extension
│   ├── tests/                    # Test programs
│   ├── examples/                 # Example applications
│   ├── hale_orbital.gpr          # GNAT project file
│   └── CONVERSION_PLAN.md
│
├── python/                       # Python reference (for comparison)
│   ├── src/
│   ├── tests/
│   ├── three-body-extension/
│   └── specs/
│
├── reference/                    # External reference material
│   ├── cubedos/                  # SPARK/Ada CubeSat framework
│   └── README.md
│
├── learning/                     # Ada learning resources
│   ├── docs/
│   └── README.md
│
├── docs/                         # Project documentation
│   ├── architecture/             # Design documents
│   ├── rationale/                # Design decision records
│   └── tutorials/                # Usage tutorials
│
└── README.md                     # Project overview
```

### Rationale for Structure

**Jean Ichbiah**: "The package hierarchy reflects the problem domain. `ada/src/` mirrors the Ada package structure. Separation of specification and implementation directories is not needed—Ada's `.ads` and `.adb` extensions provide this naturally."

**Tucker Taft**: "The `examples/` directory enables practical demonstrations of contracts and modern Ada features. The `threebody/` child package follows Ada 95's hierarchical library convention."

**John Barnes**: "The `docs/rationale/` directory captures design decisions, following the tradition of the Ada Rationale documents. This is essential for education."

**Robert Dewar**: "The GNAT project file at the `ada/` level allows simple `gprbuild -P ada/hale_orbital.gpr`. No complex paths needed."

**Benjamin Brosgol**: "The structure supports certification. Source traceability, test organization, and clear module boundaries are essential for DO-178C compliance."

---

## Consensus: Role Assignments

### Lead Responsibilities

| Area | Primary | Support |
|------|---------|---------|
| **Architecture** | Jean Ichbiah | Tucker Taft |
| **Modern Features** | Tucker Taft | Jean Ichbiah |
| **Documentation** | John Barnes | All |
| **Implementation** | Robert Dewar | Tucker Taft |
| **Certification** | Benjamin Brosgol | John Barnes |
| **SPARK Proofs** | Benjamin Brosgol | Tucker Taft |

### Handoff Patterns

When one agent needs another's expertise:

1. **Architecture questions** → Jean Ichbiah
2. **Ada 2012+ features** → Tucker Taft
3. **Educational clarity** → John Barnes
4. **Performance optimization** → Robert Dewar
5. **Certification/safety** → Benjamin Brosgol

### Collaboration Triggers

- **Type design**: Jean leads, Tucker adds contracts
- **Solver implementation**: Robert optimizes, Ben adds SPARK
- **Documentation**: John leads, all contribute domain expertise
- **Testing**: Ben defines coverage, Robert implements efficiently
- **API design**: Tucker leads modern patterns, Jean reviews architecture

---

## Consensus: Code Review Checklist

All agents agree to evaluate code against this unified checklist:

### Architecture (Jean)
- [ ] Package structure reflects problem domain
- [ ] Specifications are stable, bodies can evolve
- [ ] Dimensional types prevent unit errors
- [ ] Design will survive decades of maintenance

### Modern Ada (Tucker)
- [ ] Pre/Post contracts on all public functions
- [ ] Expression functions for simple operations
- [ ] Type invariants for complex types
- [ ] SPARK aspects where applicable

### Clarity (John)
- [ ] Names are meaningful in problem domain
- [ ] Code is self-documenting
- [ ] Comments explain "why" not "what"
- [ ] A newcomer could understand this

### Performance (Robert)
- [ ] Hot paths are inlined
- [ ] Expression functions used for zero overhead
- [ ] Pragmas documented and justified
- [ ] Compiles with -O3 -gnatn2

### Safety (Benjamin)
- [ ] SPARK mode where possible
- [ ] No exceptions in safety-critical paths
- [ ] Loop invariants prove termination
- [ ] Resource bounds are explicit

---

## Project Register Boards

### Location
Project registers are maintained in `.claude/PROJECT_REGISTERS.md`

### Register Types

1. **Decision Register** - Architectural and design decisions
2. **Issue Register** - Known issues and their status
3. **Risk Register** - Safety and technical risks
4. **Action Register** - Tasks and assignments
5. **Review Register** - Code review history

See `PROJECT_REGISTERS.md` for current state.

---

## Amendment Process

Any agent may propose amendments to this protocol. Amendments require:
1. Written proposal with rationale
2. Review by all 5 agents
3. Unanimous or 4/5 majority approval
4. Documentation of dissenting opinions

---

*Signed by unanimous consent of the Expert Panel, January 2026*

**Jean Ichbiah** | **Tucker Taft** | **John Barnes** | **Robert Dewar** | **Benjamin Brosgol**

