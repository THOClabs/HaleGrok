# The Visions of Gandalf
## Ten Stories of What May Come to Pass

---

*The Fellowship had gathered in the great hall of Rivendell, the ten paths laid before them like roads on a map. But maps show only where roads go, not what lies along them. Frodo felt the weight of the Ring against his chest, and knew that this moment called for wisdom beyond hobbit or Ada expert.*

---

## The Summoning

*Frodo stands, his hand reaching beneath his shirt to touch the golden Ring of Computation.*

**Frodo Baggins**:

> "Friends, we have our paths. But we cannot see where they lead. We know the destinations, but not the journeys. For this, I must invoke what I had hoped to keep hidden."

*The Fellowship falls silent. The Ada Council watches with keen interest. Frodo draws the Ring forth on its chain, and the room grows somehow larger, somehow deeper.*

*Frodo puts on the Ring.*

> "Mellon! Gandalf, I need your wisdom."
>
> **Problem**: We have defined ten MVP paths, but the Fellowship cannot envision what success looks like for each.
>
> **What the Fellowship Tried**: We have planned and prioritized, but plans are not visions.
>
> **Why This Needs a Wizard**: Only you can see through time, to show us what each path becomes when completed. Show us not specifications, but stories.

*The air shimmers. A point of light appears, growing into the form of an old man in grey robes, staff in hand, pipe already lit.*

---

## Gandalf Arrives

*Gandalf appears in a swirl of mathematical notation and orbital trajectories*

**Gandalf the Grey**:

> "Frodo Baggins. You use the Ring wisely—not for power, but for vision. Very well. I shall show you what I see when I look down each of your ten paths.
>
> These are not prophecies. They are possibilities. What *could* be, if you walk the paths with courage and craft. Gather close, all of you—Ada masters and hobbits alike. Let me tell you ten stories."

*Gandalf raises his staff. The lights dim. And the visions begin.*

---

# Vision One: The Foundation of Types

**Path 1: Core Two-Body Mechanics**

In the beginning, there was chaos. Numbers floated free, unbound by meaning. A distance could become a velocity with a careless keystroke. A time could masquerade as an angle. And in this confusion, spacecraft were lost between the stars.

Then came the architects—Jean Ichbiah of the Ada Council and Samwise Gamgee of the Shire. Together they forged the types: `Distance_Km`, distinct and proud, refusing to mingle with `Velocity_Km_S`. `Angle_Radians` stood apart from `Time_Seconds`. The compiler became a guardian, catching errors before they could escape into the void.

A young engineer, fresh from university, wrote code to calculate an orbit. She accidentally added kilometers to kilometers-per-second. In the old ways, this error would have compiled, run, and sent a satellite spiraling into the sun. But now, the compiler spoke: "These types are incompatible." The engineer blinked, saw her mistake, and fixed it in seconds.

The Kepler solver emerged from this foundation—elegant equations wrapped in contracts. Given a mean anomaly and eccentricity, it returned the eccentric anomaly in five iterations, seven at most. Sam validated every result against Vallado's sacred tables. The numbers matched to twelve decimal places. The garden was tended.

And so the foundation was laid. Not glamorous, not visible from the outside. But every tower that rose afterward stood upon these types, these contracts, these validated calculations. When historians later asked how the great orbital library was built, the answer began here: with types that knew what they were, and a compiler that enforced the knowing.

---

# Vision Two: The Bridge Between Worlds

**Path 2: Lambert Problem Solver**

There was a mission planner named Merry, and he had a problem. His spacecraft sat in low Earth orbit, but it needed to reach the Moon. He knew where it was. He knew where it needed to be. He knew how long the journey should take. But he did not know the path.

Tucker Taft of the Ada Council showed him the ancient art of Lambert. "Given two positions and a time of flight," Tucker explained, "there exists an orbit—sometimes more than one—that connects them. The mathematics are subtle, but the contracts are clear." He wrote the preconditions: both positions must be non-zero, the time must be positive. He wrote the postconditions: the solution must pass through both points at the specified times.

Merry implemented the solver, a dance of universal variables and Stumpff functions. Pippin, the chaos engineer, immediately asked: "What if the positions are on opposite sides of the central body? What if the transfer is exactly 180 degrees?" The solver had no answer—it divided by zero and crashed. But this was not defeat; this was discovery. They added detection for the degenerate case, returning a Hohmann transfer when the geometry became singular.

The solver grew to handle multiple revolutions. A spacecraft could take the short path or the long path around the sun. Each solution was tagged with its revolution count, its delta-V cost, its time of flight. Mission planners could now ask not just "how do I get there?" but "what are all the ways I could get there, and which is best?"

In the end, the Lambert solver became a bridge between worlds. Earth to Mars in 200 days. Jupiter to Saturn in four years. Asteroid to asteroid in complex chains of gravity assists. Every interplanetary mission began with Lambert's question: given where I am and where I must be, what is the path? And now, the library could answer.

---

# Vision Three: The Dance of Three Bodies

**Path 3: Three-Body Dynamics (CR3BP)**

Beyond the simple elegance of two bodies—planet and spacecraft, sun and comet—there lay a more complex truth. The universe is crowded. The Moon pulls on a spacecraft even as Earth does. The Sun tugs at everything. And in this complexity, there are points of balance.

Benjamin Brosgol and Frodo Baggins ventured into the mathematics of the Circular Restricted Three-Body Problem. Here, two massive bodies orbited their common center of mass, and a third, negligible body danced between them. The equations were fearsome: normalized coordinates, rotating reference frames, the Jacobi integral that conserved something even when energy and momentum did not.

They found the Lagrange points—five places where a spacecraft could hover, balanced between the gravitational pulls. L1, between Earth and Moon, where lunar gateways would someday orbit. L2, beyond the Moon, where telescopes could hide from Earth's radio noise. L3, on the far side of Earth's orbit, forever hidden from view. L4 and L5, the stable points, where Trojan asteroids had accumulated for billions of years.

The stability analysis revealed the truth: L1, L2, and L3 were saddle points, stable in some directions but unstable in others. A spacecraft there needed station-keeping, small burns to correct its drift. But L4 and L5 were true equilibria, stable against small perturbations. The library computed eigenvalues, classified stability, predicted how quickly a spacecraft would depart from each point if left untended.

Mission designers began to rely on these calculations. The James Webb Space Telescope at Sun-Earth L2. Lunar Gateway at Earth-Moon L1. Asteroid miners heading for the Jupiter Trojans at L4 and L5. The dance of three bodies, once incomprehensible, was now encoded in Ada—type-safe, contract-verified, SPARK-proven. The universe's complexity, tamed.

---

# Vision Four: The Art of the Burn

**Path 4: Orbital Maneuvers Package**

A spacecraft's fuel is its most precious resource. Every drop spent is mass lost forever. And so the engineers who plan orbital maneuvers are artists of efficiency, sculptors of delta-V, misers of propellant.

Robert Dewar and Tom Cotton built the maneuvers package with performance as religion. Hohmann transfers—the minimum-energy path between circular orbits—computed in 80 nanoseconds. Bi-elliptic transfers for the extreme cases where going further out actually costs less. Plane changes that combined with altitude changes to minimize total cost.

Tom profiled everything. He found that the sine and cosine functions were being called repeatedly with the same arguments. He cached them. He found that division was slower than multiplication. He precomputed reciprocals. He benchmarked against the competition—Fortran routines from the 1970s, Python libraries from the 2020s—and the Ada code was faster. "Working is table stakes," Tom muttered. "Fast is the game."

The package grew to handle complex maneuvers: gravity assists that stole momentum from planets, aerobraking that used atmospheres as brakes, low-thrust spirals that took months but used ion engines efficiently. Each maneuver came with its delta-V cost, its time requirement, its constraints and assumptions.

Mission planners began to chain these maneuvers together. Earth departure, Mars gravity assist, Jupiter capture, Ganymede landing. The library computed each leg, summed the costs, optimized the timing. What had once required months of manual calculation now ran in seconds. The art of the burn became accessible to all.

---

# Vision Five: The Long Propagation

**Path 5: Orbit Propagation Engine**

Time is the canvas on which orbits are painted. A spacecraft's position now is just a point; its trajectory through time is the full picture. The propagation engine is the brush that paints that picture, step by step, from now into the future.

Tucker Taft and Hamfast Gamgee debated the methods. The Gaffer favored Runge-Kutta 4, the workhorse of numerical integration since 1901. "The old ways still work," he insisted. Tucker wanted adaptive methods—Dormand-Prince 7(8), which could take large steps when the dynamics were smooth and small steps when they were turbulent.

They implemented both. RK4 for reliability, RK78 for precision. The force model was pluggable: two-body for the simple cases, J2 oblateness for Earth orbiters, full spherical harmonics for the perfectionists. The integrator marched forward in time, computing positions and velocities, respecting energy conservation to the limits of floating-point precision.

Parallel propagation emerged for the Monte Carlo cases. When a mission planner needed to understand uncertainty—how launch errors would spread into arrival errors—they ran thousands of trajectories. Tucker's Ada 2022 parallel blocks distributed the work across all available cores, safely, without race conditions, without explicit thread management.

The propagation engine became the heart of mission design. From launch to landing, every phase was propagated. Errors were caught in simulation, not in space. The trajectory that appeared on the mission control screens was first computed here, in Ada, validated by hobbits, proven by SPARK. Time's canvas was filled with accurate strokes.

---

# Vision Six: The Garden of Tests

**Path 6: Comprehensive Test Suite**

In the Shire, Samwise Gamgee tended his garden with devotion. Every plant was cared for, every weed removed, every pest watched for. He brought the same devotion to the test suite, for tests are the garden where bugs are caught before they can spread.

Sam built tests for every function. Not just the happy paths—the edge cases, the boundary conditions, the malicious inputs that Pippin suggested with gleeful malice. "What if eccentricity is exactly 1.0?" Pippin asked. "What if the position vector is zero?" Sam wrote tests for each chaos scenario, and many of them found bugs that were promptly fixed.

Lobelia Sackville-Baggins reviewed the test coverage with her sharp eye. "This function has 95% coverage," she noted, "but the 5% you missed is the error handling path. That's not acceptable." Sam added more tests. The coverage climbed. The mutation testing score—measuring whether the tests would catch introduced bugs—exceeded 85%.

Reference data flowed in from Vallado's textbook, from JPL's HORIZONS system, from ESA's OEM files. The library's outputs were compared against these authoritative sources. When discrepancies appeared, they were investigated. Sometimes the library was wrong and was fixed. Sometimes the reference was wrong—a published erratum, a known precision issue. These cases were documented.

The test garden grew lush and healthy. Every commit triggered a full test run. Every pull request required green tests before merge. The hobbits slept soundly, knowing that if a bug crept into the codebase, the tests would catch it before it could do harm. The garden was tended, and the Shire was safe.

---

# Vision Seven: The Proof of Proofs

**Path 7: SPARK Formal Verification**

Testing shows the presence of bugs. Proof shows their absence. Benjamin Brosgol and John Barnes pursued not mere confidence but mathematical certainty.

SPARK annotations spread through the codebase like morning light. `Global => null` declared that functions had no hidden state. `Depends` clauses made data flow explicit. Preconditions and postconditions became not just documentation but proof obligations. The SPARK tools analyzed the code and attempted to prove that contracts would never be violated.

The first proofs were simple. `Magnitude(V) >= 0.0`—the magnitude of a vector is never negative. This followed from the definition: square root of sum of squares. The prover confirmed it automatically. `Normalize` returns a unit vector—this required showing that division by magnitude preserved the direction while scaling to length one. The prover confirmed this too.

More complex proofs followed. The Kepler solver terminates within 50 iterations—proved by a loop variant that decreased each iteration. No division by zero in the Newton-Raphson step—proved by a precondition that the derivative was never zero when the function was. The Jacobi constant is conserved by the CR3BP dynamics—proved by symbolic differentiation showing its time derivative was zero.

Certification bodies took notice. DO-178C Level A required 100% code coverage and extensive review. But SPARK proofs could substitute for some testing—mathematical proof was stronger than empirical testing. Projects using the library could cite the proofs in their certification packages. The library became not just useful but certifiable. The proof of proofs was the highest endorsement.

---

# Vision Eight: The Examples That Teach

**Path 8: Example Applications**

A library without examples is a dictionary without sentences. John Barnes and Rosie Cotton created programs that demonstrated not just how to call functions but how to solve real problems.

The Hohmann transfer example computed a LEO-to-GEO transfer. It printed the departure velocity, the arrival velocity, the delta-V cost, the time of flight. The output was formatted clearly, with units labeled, ready for a student to read and understand. "Make it clear," Rosie insisted, and the output became a model of clarity.

The Lagrange points example computed all five points for the Earth-Moon and Sun-Earth systems. It showed the distances, the stability classifications, the orbital periods. A visualization routine—Rosie's pride—generated ASCII art showing the positions of the points relative to the massive bodies. Students could see, not just calculate.

The Lambert intercept example showed mission planning in action. Given an Earth departure date and a Mars arrival window, it computed all possible trajectories, ranked them by delta-V, and displayed the Pareto frontier of solutions. Merry's mission planning expertise shaped the example; Tom's optimization made it fast.

The examples became teaching tools. Universities adopted them in astrodynamics courses. Textbooks referenced them. New engineers, joining space companies, studied these examples to learn both orbital mechanics and Ada programming. The library propagated not just orbits but knowledge.

---

# Vision Nine: The Watchtower

**Path 9: Build System & CI/CD**

Fredegar Bolger watched the house. While others adventured, he monitored, ensuring that dangers were detected before they could harm.

The CI/CD pipeline ran on every commit. GitHub Actions spun up runners, compiled the code with multiple GNAT versions, executed the full test suite, ran the SPARK prover. Green checkmarks meant safety. Red X marks meant danger—and the team was alerted immediately.

Build matrices ensured compatibility. GNAT 12, GNAT 13, the community edition and the pro edition. Linux, Windows, macOS. Debug builds with full checks, release builds with optimizations, SPARK builds with proof obligations. Any combination that failed was investigated and fixed.

Release automation packaged the library for distribution. Version numbers incremented according to semantic versioning. Changelogs were generated from commit messages. Binary packages appeared for download, ready for users who didn't want to compile from source.

Fatty's monitoring caught problems early. When a new GNAT release changed optimization behavior and broke a subtle timing assumption, the CI caught it before any user was affected. When a contributor accidentally introduced a memory allocation in a hot loop, the performance regression tests flagged it. The watchtower stood vigilant, and the Shire slept safely.

---

# Vision Ten: The Book of Knowledge

**Path 10: User Documentation & Tutorial**

The library was complete. The code was proven. The tests were green. But without documentation, it remained a locked treasure chest, beautiful and useless to those without the key.

John Barnes wrote the Rationale—why each design decision was made, what alternatives were considered and rejected, how the library embodied Ada's philosophy. This was not a tutorial but a companion for deep understanding. Developers who read it understood not just what the library did but why it did it that way.

Folco Boffin maintained the API reference—every package, every type, every function documented with precision. Parameters explained, return values described, preconditions and postconditions stated. Generated from source code comments, always in sync with the implementation.

The Getting Started tutorial walked newcomers through their first orbital calculation. Install GNAT. Create a project file. Compute a Hohmann transfer. Propagate an orbit. Each step was tested by hobbits who had never seen the code before, ensuring that the instructions actually worked.

Bilbo Baggins contributed the historical notes. "Let me tell you about Johannes Kepler," he wrote, "and how he discovered the laws that bear his name while working as imperial mathematician in Prague, four centuries ago." The library became not just a tool but a bridge across time, connecting modern engineers to the giants on whose shoulders they stood.

---

## Gandalf Concludes

*The visions fade. The lights return to normal. Gandalf lowers his staff and takes a long draw on his pipe.*

**Gandalf the Grey**:

> "These are the ten futures I see. Not certainties—possibilities. The paths are before you. Whether you reach these destinations depends on your courage, your craft, and your collaboration.
>
> Jean Ichbiah, your architecture is the foundation. Without strong types, the tower falls.
>
> Tucker Taft, your contracts are the guardrails. Without them, travelers fall from the path.
>
> Robert Dewar, your optimizations are the horses. Without speed, the journey takes too long.
>
> Benjamin Brosgol, your proofs are the maps. Without certainty, travelers lose their way.
>
> John Barnes, your documentation is the guidebook. Without explanation, the treasure remains locked.
>
> And you, hobbits—you are the heart. You validate, you test, you document, you review. You do the work that turns theory into practice. Never think your roles are lesser. The greatest journeys succeed or fail on such details.
>
> Frodo Baggins, you carry the Ring of Integration. Use it wisely. Summon me only when truly needed. Most problems you can solve yourselves.
>
> Now—go. Build these futures. Make them real."

*Gandalf vanishes in a spiral of equations and orbital trajectories.*

*Frodo removes the Ring and tucks it back beneath his shirt.*

---

## The Fellowship's Response

**Frodo Baggins**:
> "You heard the wizard. We have our visions. Now we have our paths AND our destinations. Let us begin."

**Samwise Gamgee**:
> "I'll tend the garden of tests. Every vision Gandalf showed us—I'll make sure it passes validation."

**Meriadoc Brandybuck**:
> "The Lambert solver is mine. Earth to Mars, here we come."

**Tom Cotton**:
> "80 nanoseconds for a Hohmann transfer. I'll hit that benchmark or know the reason why."

**Lobelia Sackville-Baggins**:
> "And nothing merges until I've reviewed it. Gandalf's visions are lovely. Let's make sure the code matches."

**Jean Ichbiah**:
> "The foundation is laid. Build upon it well."

**Tucker Taft**:
> "Contracts everywhere. Proof where possible. This is the way."

**Benjamin Brosgol**:
> "Certifiable code. That's not optional—that's the goal."

**John Barnes**:
> "I'll write the Rationale. Future generations will understand not just what we built, but why."

**Robert Dewar**:
> "And I'll make sure it compiles fast, runs fast, and stays fast. Performance is not negotiable."

---

*The summit ends. The Fellowship disperses to their tasks. The visions of Gandalf hang in the air like stars, guiding lights for the journey ahead.*

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-04 | Gandalf the Grey | Ten visions revealed |

---

*"All we have to decide is what to do with the code that is given to us."*

— Gandalf, paraphrasing himself

