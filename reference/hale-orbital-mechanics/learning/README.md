# Ada Programming Language Learning Resources

This folder contains learning materials for the Ada programming language, specifically for developing safety-critical aerospace software.

## Downloaded PDFs

### Core Ada Learning

| File | Description | Size |
|------|-------------|------|
| `intro-to-ada.pdf` | Introduction to Ada - Beginner's guide | 1.1 MB |
| `learning-ada.pdf` | Comprehensive Ada learning book | 11 MB |
| `ada-for-embedded.pdf` | Ada for Embedded Systems Programming | 2.4 MB |
| `spark-ada-intro.pdf` | Introduction to SPARK (formal verification) | 790 KB |

### Source
All PDFs from: https://learn.adacore.com/

## Online Resources

### Official Documentation

| Resource | URL | Description |
|----------|-----|-------------|
| Ada 2012 Reference Manual | http://www.ada-auth.org/standards/ada12.html | Official language specification |
| Ada Resource Association | https://adaic.org/learn/materials/ | Learning materials index |
| AdaCore Learn | https://learn.adacore.com/ | Interactive tutorials |
| GNAT Documentation | https://docs.adacore.com/ | Compiler and tools docs |

### Tutorials

| Resource | URL | Description |
|----------|-----|-------------|
| Ada Wikibook | https://en.wikibooks.org/wiki/Ada_Programming | Community wiki tutorial |
| Ada 95 Tutorial | https://perso.telecom-paristech.fr/pautet/Ada95/a95list.htm | 33-chapter complete course |
| Lovelace Tutorial | https://dwheeler.com/lovelace/ | Free online Ada tutorial |

### Books (Free Online)

| Title | Author | URL |
|-------|--------|-----|
| Ada Distilled | Richard Riehle | https://www.adaic.org/wp-content/uploads/2010/05/Ada-Distilled-24-January-2011-Ada-2005-Version.pdf |
| Ada 95 Rationale | John Barnes | https://www.adaic.org/resources/add_content/standards/95rat/rat95html/rat95-contents.html |

## Key Ada Concepts for Orbital Mechanics

### 1. Strong Typing
```ada
type Distance_Km is new Long_Float;
type Velocity_Km_S is new Long_Float;
type Time_Seconds is new Long_Float;

-- Compiler prevents: Distance_Km + Velocity_Km_S (type mismatch)
```

### 2. Range Constraints
```ada
type Eccentricity is new Long_Float range 0.0 .. Long_Float'Last;
type Inclination is new Long_Float range 0.0 .. Ada.Numerics.Pi;
```

### 3. Record Types (like structs)
```ada
type Orbital_Elements is record
   Semi_Major_Axis : Distance_Km;
   Eccentricity    : Long_Float range 0.0 .. Long_Float'Last;
   Inclination     : Angle_Radians;
   RAAN            : Angle_Radians;
   Arg_Periapsis   : Angle_Radians;
   True_Anomaly    : Angle_Radians;
end record;
```

### 4. Exception Handling
```ada
Convergence_Error : exception;
Invalid_Orbit     : exception;

function Solve_Kepler (M, E : Long_Float) return Long_Float is
begin
   -- Newton-Raphson iteration
   if Iterations > Max_Iter then
      raise Convergence_Error with "Kepler solver failed";
   end if;
   return Result;
end Solve_Kepler;
```

### 5. Generics (Templates)
```ada
generic
   type Real_Type is digits <>;
   with function F (X : Real_Type) return Real_Type;
function Newton_Raphson (Initial : Real_Type) return Real_Type;
```

### 6. Packages (Modules)
```ada
-- Specification (hale_orbital-twobody.ads)
package Hale_Orbital.Twobody is
   function Vis_Viva (R, A : Distance_Km; Mu : Grav_Param) return Velocity_Km_S;
end Hale_Orbital.Twobody;

-- Body (hale_orbital-twobody.adb)
package body Hale_Orbital.Twobody is
   function Vis_Viva (R, A : Distance_Km; Mu : Grav_Param) return Velocity_Km_S is
   begin
      return Velocity_Km_S (Sqrt (Mu * (2.0/R - 1.0/A)));
   end Vis_Viva;
end Hale_Orbital.Twobody;
```

## SPARK for Safety-Critical Code

SPARK is a formally verifiable subset of Ada used in aerospace:

```ada
package Kepler_Solver
   with SPARK_Mode => On
is
   function Solve (M : Mean_Anomaly; E : Eccentricity) return Eccentric_Anomaly
      with Pre  => E >= 0.0 and E < 1.0,
           Post => Solve'Result in 0.0 .. 2.0 * Pi;
end Kepler_Solver;
```

## Learning Path for Orbital Mechanics Development

1. **Week 1-2**: Read `intro-to-ada.pdf`
   - Basic syntax, types, control flow
   - Packages and separate compilation

2. **Week 3-4**: Study `ada-for-embedded.pdf`
   - Low-level programming
   - Real-time features
   - Interfacing with hardware

3. **Week 5-6**: Study `learning-ada.pdf` (advanced topics)
   - Object-oriented features
   - Generics and containers
   - Tasking and concurrency

4. **Week 7-8**: Study `spark-ada-intro.pdf`
   - Formal verification
   - Contracts and proofs
   - Safety-critical development

5. **Ongoing**: Reference the Ada 2012 manual for specifics

## Building Ada Programs

### Install GNAT
```bash
# Ubuntu/Debian
apt-get install gnat

# Or download GNAT Community from:
# https://www.adacore.com/download
```

### Compile a simple program
```bash
# Single file
gnatmake hello.adb

# Project-based (recommended)
gprbuild -P my_project.gpr
```

### Project file example
```ada
project My_Project is
   for Source_Dirs use ("src");
   for Object_Dir use "obj";
   for Main use ("main.adb");

   package Compiler is
      for Default_Switches ("Ada") use ("-gnat2012", "-gnatwa", "-gnata");
   end Compiler;
end My_Project;
```

## Useful GNAT Switches

| Switch | Description |
|--------|-------------|
| `-gnat2012` | Use Ada 2012 standard |
| `-gnatwa` | Enable all warnings |
| `-gnata` | Enable assertions |
| `-gnatVa` | All validity checks |
| `-gnato` | Overflow checking |
| `-gnatp` | Suppress all checks (release) |
| `-g` | Debug information |
| `-O2` | Optimization level 2 |

## Resources in `reference/` Folder

See the `../reference/` folder for:
- **CubedOS**: SPARK/Ada flight software framework
- **GNAT Studio**: IDE source code (Ada patterns)
- **Ada Drivers Library**: Embedded Ada examples
