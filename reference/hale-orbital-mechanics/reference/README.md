# Ada Reference Code

This folder contains open-source Ada projects relevant to aerospace and embedded systems development.

## Contents

### CubedOS (`cubedos/`)
**Source**: https://github.com/cubesatlab/cubedos

A flight software framework for CubeSat spacecraft written in **SPARK/Ada**. The core is verified to be free of runtime errors using SPARK formal verification.

Key features:
- Modular message-passing architecture
- SPARK verification for safety-critical code
- Real-time operating system support
- Hardware abstraction layers

Relevant modules for orbital mechanics:
- Message passing infrastructure
- Time management
- State machine patterns

### Awesome Ada (`awesome-ada/`)
**Source**: https://github.com/ohenley/awesome-ada

A curated list of Ada and SPARK resources including:
- Numerical libraries
- Embedded development
- Web development
- Testing frameworks
- IDEs and tools

### GNAT Studio (`gnatstudio/`)
**Source**: https://github.com/AdaCore/gnatstudio

The official IDE for Ada and SPARK development. Useful for:
- Understanding Ada project structure
- Reference for Ada coding patterns
- GPS project file examples

### Ada Drivers Library (`Ada_Drivers_Library/`)
**Source**: https://github.com/AdaCore/Ada_Drivers_Library

Hardware abstraction layers for embedded Ada development. Contains:
- Device drivers (I2C, SPI, UART)
- Board support packages
- Real-time patterns

### Libadalang (`libadalang/`)
**Source**: https://github.com/AdaCore/libadalang

Ada/SPARK analysis library. Useful for:
- Understanding Ada syntax and semantics
- Ada 2012/2022 language features
- Code analysis patterns

## Relevant Ada Libraries for Orbital Mechanics

Based on the awesome-ada list, these libraries may be useful:

| Library | Description | URL |
|---------|-------------|-----|
| lalg | Dense linear algebra interface | https://github.com/jhumphry/LALG |
| Ada Numerics | BLAS/LAPACK bindings | (in GNAT standard library) |
| Simple Components | Generic containers, I/O, crypto | http://www.dmitry-kazakov.de/ada/components.htm |

## Space Industry Ada Usage

Ada is used in major aerospace projects:
- **International Space Station** - Mobile Servicing System (MDA/GNAT)
- **ExoMars** - Trace Gas Orbiter and EDM (Thales Alenia Space)
- **Vega-C Launch Vehicle** - On-board software (AVIO)
- **Boeing 787** - Common Core System avionics
- **Eurofighter** - Mission computers (BAE Systems)
- **Lunar IceCube** - CubeSat mission (Vermont Tech)

## Notes

These repositories are cloned with `--depth 1` to save space. For full history:
```bash
git fetch --unshallow
```
