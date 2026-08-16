# Team Review Session
## Selecting the Hybrid Path

*Date: The Fourth Age of Ada (2026)*
*Location: The Council Chamber, Rivendell*

---

## Session Opening

*The Fellowship and Ada Council reconvene after Gandalf's departure. The ten visions hang in the air like constellations. The task now is to choose wisely.*

**Frodo Baggins** *(Team Lead)*:

> "Gandalf showed us ten futures. But we cannot walk ten paths at once. We must choose which paths can be woven together, combined into a single hybrid journey that delivers the most value.
>
> Let us review each vision and vote on which belong together."

---

## Path Analysis

### Already Complete (Foundation)

**Jean Ichbiah**:
> "Vision One—the Foundation of Types—is already built. Vision Three—the Dance of Three Bodies—is also substantially complete. These are our base camp. We need not include them in the hybrid; they are already achieved."

| Vision | Status | Include in Hybrid? |
|--------|--------|-------------------|
| 1. Foundation of Types | ✅ Complete | No (already done) |
| 3. Three-Body Dynamics | ✅ Complete | No (already done) |

### Support Paths (Parallel Tracks)

**Lobelia Sackville-Baggins**:
> "Vision Six (Tests), Vision Seven (SPARK Proofs), and Vision Nine (CI/CD) are support paths. They should run in parallel with whatever we build, not be combined into it. Every feature we implement needs tests. Every function needs proofs. Every commit needs CI."

**Benjamin Brosgol**:
> "Lobelia is correct. Quality assurance is not a feature; it's a way of working. These paths accompany all others."

| Vision | Status | Include in Hybrid? |
|--------|--------|-------------------|
| 6. Garden of Tests | 🔄 Ongoing | No (parallel track) |
| 7. Proof of Proofs | 🔄 Ongoing | No (parallel track) |
| 9. Watchtower (CI/CD) | 📋 Planned | No (parallel track) |

### Documentation Path

**John Barnes**:
> "Vision Ten—the Book of Knowledge—should follow implementation, not precede it. We cannot document what we haven't built. This path waits until we have something to document."

**Folco Boffin**:
> "But I'll take notes as we go! Documentation starts now, even if the book is written later."

| Vision | Status | Include in Hybrid? |
|--------|--------|-------------------|
| 10. Book of Knowledge | 📋 Planned | No (follows implementation) |

---

## The Hybrid Path Selection

*This leaves Visions 2, 4, 5, and 8 as candidates for the hybrid path.*

**Meriadoc Brandybuck** *(Mission Planning)*:
> "Look at these four visions:
> - **Vision 2**: Lambert Solver (how do we get from A to B?)
> - **Vision 4**: Orbital Maneuvers (what burns do we need?)
> - **Vision 5**: Propagation (where are we over time?)
> - **Vision 8**: Examples (show it working)
>
> These are not separate paths—they're one journey! A mission planner needs ALL of these together. You can't plan a Mars mission with just Lambert. You need the maneuvers, the propagation, and examples showing it all works."

**Tucker Taft**:
> "Merry is right. These four visions form a natural unit: **Mission Planning Capability**. Lambert finds the path. Maneuvers calculate the burns. Propagation traces the trajectory. Examples prove it works."

**Robert Dewar**:
> "And from an implementation standpoint, they share infrastructure. The propagator needs force models. Lambert needs the propagator for validation. Maneuvers need both for mission sequences. Build them together."

**Tom Cotton**:
> "I can optimize them together too. Shared math routines, cached computations, parallel execution. One optimized hybrid, not four separate silos."

---

## The Vote

**Frodo Baggins**:
> "All in favor of combining Visions 2, 4, 5, and 8 into the **Mission Planning Hybrid Path**?"

### Ada Council Vote

| Expert | Vote | Comment |
|--------|------|---------|
| Jean Ichbiah | ✅ Aye | "Architecturally coherent" |
| Tucker Taft | ✅ Aye | "Contracts will compose well" |
| Robert Dewar | ✅ Aye | "Optimizable as a unit" |
| Benjamin Brosgol | ✅ Aye | "Certifiable as integrated system" |
| John Barnes | ✅ Aye | "Teachable as complete workflow" |

### Fellowship Vote

| Hobbit | Vote | Comment |
|--------|------|---------|
| Frodo Baggins | ✅ Aye | "The paths are now one" |
| Samwise Gamgee | ✅ Aye | "I can validate end-to-end" |
| Meriadoc Brandybuck | ✅ Aye | "This IS mission planning" |
| Peregrin Took | ✅ Aye | "More ways to break things!" |
| Fredegar Bolger | ✅ Aye | "One system to monitor" |
| Folco Boffin | ✅ Aye | "One story to document" |
| Hamfast Gamgee | ✅ Aye | "Sensible combination" |
| Rosie Cotton | ✅ Aye | "Beautiful trajectories to visualize" |
| Bilbo Baggins | ✅ Aye | "Gauss and Lambert together at last" |
| Lobelia S-B | ✅ Aye | "One review, not four" |
| Tom Cotton | ✅ Aye | "Optimize once, benefit everywhere" |

**Result: UNANIMOUS (16-0)**

---

## The Hybrid Path: Mission Planning Capability

```
┌─────────────────────────────────────────────────────────────────┐
│                  MISSION PLANNING HYBRID PATH                    │
│                                                                  │
│  Visions Combined: 2 (Lambert) + 4 (Maneuvers) + 5 (Propagation)│
│                    + 8 (Examples)                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│   │   LAMBERT   │────▶│  MANEUVERS  │────▶│ PROPAGATION │       │
│   │   Solver    │     │   Package   │     │   Engine    │       │
│   │             │     │             │     │             │       │
│   │ "Where can  │     │ "What burns │     │ "Trace the  │       │
│   │  we go?"    │     │  do we need?"    │  trajectory" │       │
│   └─────────────┘     └─────────────┘     └─────────────┘       │
│          │                   │                   │               │
│          └───────────────────┼───────────────────┘               │
│                              ▼                                   │
│                    ┌─────────────────┐                          │
│                    │    EXAMPLES     │                          │
│                    │                 │                          │
│                    │ "Prove it works"│                          │
│                    └─────────────────┘                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Scope of the Hybrid Path

### From Vision 2: Lambert Solver
- Complete universal variable formulation
- Multi-revolution solutions
- Degenerate case handling (180° transfer)
- Integration with maneuvers for delta-V calculation

### From Vision 4: Orbital Maneuvers
- Implement Hohmann transfer body (specification exists)
- Implement bi-elliptic transfer
- Implement plane change maneuvers
- Implement phasing/rendezvous
- Escape and capture maneuvers

### From Vision 5: Propagation Engine
- Complete RK4 implementation
- Add RK78 Dormand-Prince adaptive
- Pluggable force models
- Parallel propagation for Monte Carlo

### From Vision 8: Examples
- Lambert intercept example
- Full mission planning example
- Visualization of results

---

## Team Assignments for Hybrid Path

| Component | Lead (Ada) | Lead (Hobbit) | Support |
|-----------|------------|---------------|---------|
| Lambert Solver | Tucker Taft | Merry | Pippin (edge cases) |
| Maneuvers Package | Robert Dewar | Tom Cotton | Sam (validation) |
| Propagation Engine | Tucker Taft | Gaffer | Tom (performance) |
| Examples | John Barnes | Rosie | Folco (docs) |
| Integration | Jean Ichbiah | Frodo | All |
| Testing | Benjamin Brosgol | Sam + Lobelia | Pippin |

---

## Success Criteria

The Hybrid Path is complete when:

1. **Lambert Solver**: Matches Vallado test cases for single and multi-rev
2. **Maneuvers**: Hohmann, bi-elliptic, plane change all validated
3. **Propagation**: RK78 conserves energy to 1e-12 over 100 orbits
4. **Examples**: Earth-Mars mission example runs end-to-end
5. **Integration**: All components work together seamlessly
6. **Quality**: Lobelia approves, Sam validates, Ben verifies SPARK

---

## Timeline Vision

**Frodo Baggins**:
> "We do not set calendar dates—that is not the hobbit way. But we can see the order of things:
>
> 1. First, complete the Lambert solver (Merry's quest)
> 2. Then, implement the maneuvers body (Tom's optimization)
> 3. Then, enhance the propagator (Gaffer's steady work)
> 4. Finally, create the mission planning example (Rosie's visualization)
>
> Each step builds on the last. We walk the path together."

---

## Closing

**Jean Ichbiah**:
> "The hybrid path is chosen. Four visions become one journey. This is good architecture—integration, not fragmentation."

**Samwise Gamgee**:
> "And I'll test every step of the way. The garden will be tended."

**Frodo Baggins**:
> "Then let us begin. The planning documents are next. Merry, Tucker—start with Lambert. The rest of us will prepare the way."

---

*Session adjourned. The team disperses to begin detailed planning.*

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-04 | The Council | Hybrid path selected |

