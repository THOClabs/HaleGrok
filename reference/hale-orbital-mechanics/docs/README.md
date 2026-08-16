# HALE Orbital Mechanics Documentation

## Directory Structure

```
docs/
├── architecture/     # System design and package structure
├── rationale/        # Design decision explanations (Ada Rationale style)
└── tutorials/        # Usage guides and examples
```

---

## Documentation Philosophy

Following John Barnes' approach to the Ada Rationale documents:

> "The key to understanding Ada is understanding *why* each feature exists."

Each document in this folder explains not just WHAT the code does, but WHY it was designed that way.

---

## Architecture Documents

| Document | Description |
|----------|-------------|
| [Package Hierarchy](architecture/package-hierarchy.md) | Package structure and dependencies |
| [Type System](architecture/type-system.md) | Dimensional types and compile-time safety |
| [SPARK Strategy](rationale/DEC-002-spark-strategy.md) | Formal verification approach |

---

## Rationale Documents

Following the tradition of the official Ada Rationale:

| Document | Description |
|----------|-------------|
| [DEC-001](rationale/DEC-001-dimensional-types.md) | Why dimensional types prevent errors |
| [DEC-002](rationale/DEC-002-spark-strategy.md) | SPARK verification strategy |
| [DEC-003](rationale/DEC-003-contract-design.md) | Why contracts over comments |
| [DEC-004](rationale/DEC-004-fp-determinism.md) | Floating-point determinism approach |
| [DEC-005](rationale/DEC-005-threebody-package-structure.md) | Three-body package organization |

---

## Tutorials

| Tutorial | Description |
|----------|-------------|
| [Getting Started](tutorials/getting-started.md) | First orbital calculation walkthrough |
| [Historical Context](history/orbital-mechanics-heritage.md) | Four centuries of orbital mechanics |

## Certification

| Document | Description |
|----------|-------------|
| [DO-178C Roadmap](certification/DO-178C-roadmap.md) | Certification pathway for safety-critical systems |

## Performance

| Document | Description |
|----------|-------------|
| [Performance Benchmarks](performance.md) | Targets, methodology, and expected results |

---

## Contributing

When adding documentation:

1. **Explain the WHY** - Don't just describe what code does
2. **Use examples** - Show working Ada code
3. **Reference sources** - Cite Hale, Vallado, ARM when applicable
4. **Keep it current** - Update when code changes

---

*"A program should read like well-written prose."* — John Barnes

