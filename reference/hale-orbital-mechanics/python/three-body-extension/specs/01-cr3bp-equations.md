# Spec 01: CR3BP Equations of Motion

## Normalized Units

In the CR3BP, we use normalized units where:
- **Length**: Distance between primaries = 1
- **Mass**: Total mass (m₁ + m₂) = 1
- **Time**: Chosen so orbital period = 2π

This means:
- Angular velocity ω = 1
- Gravitational constant G = 1
- Mass ratio μ = m₂/(m₁ + m₂)

## Primary Positions (Rotating Frame)

- Larger primary (m₁): **(-μ, 0, 0)**
- Smaller primary (m₂): **(1-μ, 0, 0)**
- Barycenter: origin

## Equations of Motion

In the rotating frame, the equations of motion are:

```
ẍ - 2ẏ = ∂Ω/∂x
ÿ + 2ẋ = ∂Ω/∂y
z̈ = ∂Ω/∂z
```

Where Ω is the pseudo-potential:

```
Ω = ½(x² + y²) + (1-μ)/r₁ + μ/r₂
```

And the distances to primaries are:
```
r₁ = √[(x+μ)² + y² + z²]
r₂ = √[(x-1+μ)² + y² + z²]
```

## Partial Derivatives

```
∂Ω/∂x = x - (1-μ)(x+μ)/r₁³ - μ(x-1+μ)/r₂³
∂Ω/∂y = y - (1-μ)y/r₁³ - μy/r₂³
∂Ω/∂z = -(1-μ)z/r₁³ - μz/r₂³
```

## State Vector

The state is 6-dimensional:
```
X = [x, y, z, ẋ, ẏ, ż]ᵀ
```

## Jacobi Constant

The only integral of motion:
```
C = 2Ω - (ẋ² + ẏ² + ż²) = 2Ω - v²
```

Properties:
- C is constant along any trajectory
- Higher C = lower energy
- C determines zero-velocity surfaces (ZVS)

## Jacobian Matrix (for STM)

The linearized dynamics matrix A where δẊ = A·δX:

```
A = | 0   0   0   1   0   0  |
    | 0   0   0   0   1   0  |
    | 0   0   0   0   0   1  |
    | Ωxx Ωxy Ωxz  0   2   0  |
    | Ωxy Ωyy Ωyz -2   0   0  |
    | Ωxz Ωyz Ωzz  0   0   0  |
```

Where Ωxx, Ωxy, etc. are second partial derivatives of Ω.

## Second Partial Derivatives

```
Ωxx = 1 - (1-μ)/r₁³ - μ/r₂³ + 3(1-μ)(x+μ)²/r₁⁵ + 3μ(x-1+μ)²/r₂⁵
Ωyy = 1 - (1-μ)/r₁³ - μ/r₂³ + 3(1-μ)y²/r₁⁵ + 3μy²/r₂⁵
Ωzz = -(1-μ)/r₁³ - μ/r₂³ + 3(1-μ)z²/r₁⁵ + 3μz²/r₂⁵
Ωxy = 3(1-μ)(x+μ)y/r₁⁵ + 3μ(x-1+μ)y/r₂⁵
Ωxz = 3(1-μ)(x+μ)z/r₁⁵ + 3μ(x-1+μ)z/r₂⁵
Ωyz = 3(1-μ)yz/r₁⁵ + 3μyz/r₂⁵
```

## Implementation Notes

1. Always check for singularities (r₁ → 0 or r₂ → 0)
2. Use double precision throughout
3. Jacobi constant conservation is the primary accuracy check
4. Integration tolerance should be at least 1e-10 for good results
