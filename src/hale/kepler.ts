/**
 * Kepler equation — Hale Ch. 4 / Ada Hale_Orbital.Kepler + Stumpff.
 */
import { DEFAULT_MAX_ITERATIONS, DEFAULT_TOLERANCE, TWO_PI } from "./constants";

export function wrapTwoPi(a: number): number {
  let x = a % TWO_PI;
  if (x < 0) x += TWO_PI;
  return x;
}

/** Newton–Raphson for E − e sin E = M */
export function solveKeplerElliptic(
  meanAnomaly: number,
  eccentricity: number,
  tolerance = DEFAULT_TOLERANCE,
  maxIter = DEFAULT_MAX_ITERATIONS,
): number {
  if (eccentricity < 0 || eccentricity >= 1) {
    throw new Error("solveKeplerElliptic: need 0 ≤ e < 1");
  }
  const M = wrapTwoPi(meanAnomaly);
  let E = eccentricity < 0.8 ? M : Math.PI;
  for (let i = 0; i < maxIter; i++) {
    const f = E - eccentricity * Math.sin(E) - M;
    const fp = 1 - eccentricity * Math.cos(E);
    const d = f / fp;
    E -= d;
    if (Math.abs(d) < tolerance) return wrapTwoPi(E);
  }
  throw new Error("solveKeplerElliptic: did not converge");
}

/** e sinh H − H = M  (Ada Solve_Kepler_Hyperbolic) */
export function solveKeplerHyperbolic(
  meanAnomaly: number,
  eccentricity: number,
  tolerance = DEFAULT_TOLERANCE,
  maxIter = DEFAULT_MAX_ITERATIONS,
): number {
  if (eccentricity <= 1) throw new Error("solveKeplerHyperbolic: need e > 1");
  let H =
    Math.abs(meanAnomaly) < 1
      ? meanAnomaly
      : Math.sign(meanAnomaly) * Math.log((2 * Math.abs(meanAnomaly)) / eccentricity + 1.8);
  for (let i = 0; i < maxIter; i++) {
    const sh = Math.sinh(H);
    const ch = Math.cosh(H);
    const f = eccentricity * sh - H - meanAnomaly;
    const fp = eccentricity * ch - 1;
    if (Math.abs(fp) < 1e-15) throw new Error("hyperbolic Kepler: derivative vanished");
    const d = f / fp;
    H -= d;
    if (Math.abs(d) < tolerance) return H;
  }
  throw new Error("solveKeplerHyperbolic: did not converge");
}

/** Barker's equation: D³ + 3D − 6M = 0, ν = 2 arctan D */
export function solveKeplerParabolic(meanAnomaly: number): number {
  const M = meanAnomaly;
  const B = 3 * M;
  const A = Math.cbrt(B + Math.sqrt(B * B + 1));
  const D = A - 1 / A;
  return 2 * Math.atan(D);
}

/** Stumpff C(z) — Ada Hale_Orbital.Stumpff.C */
export function stumpffC(z: number): number {
  if (Math.abs(z) < 1e-8) return 0.5 - z / 24 + (z * z) / 720;
  if (z > 0) {
    const s = Math.sqrt(z);
    return (1 - Math.cos(s)) / z;
  }
  const s = Math.sqrt(-z);
  return (Math.cosh(s) - 1) / -z;
}

/** Stumpff S(z) — Ada Hale_Orbital.Stumpff.S */
export function stumpffS(z: number): number {
  if (Math.abs(z) < 1e-8) return 1 / 6 - z / 120 + (z * z) / 5040;
  if (z > 0) {
    const s = Math.sqrt(z);
    return (s - Math.sin(s)) / (s * s * s);
  }
  const s = Math.sqrt(-z);
  return (Math.sinh(s) - s) / (s * s * s);
}

export function trueAnomalyFromE(E: number, e: number): number {
  const tanHalf = Math.sqrt((1 + e) / (1 - e)) * Math.tan(E / 2);
  return wrapTwoPi(2 * Math.atan(tanHalf));
}

export function eccentricFromTrue(nu: number, e: number): number {
  const tanHalf = Math.sqrt((1 - e) / (1 + e)) * Math.tan(nu / 2);
  return wrapTwoPi(2 * Math.atan(tanHalf));
}

export function meanFromE(E: number, e: number): number {
  return wrapTwoPi(E - e * Math.sin(E));
}

/** Sample a coplanar ellipse in the XY plane, periapsis on +X. */
export function sampleEllipse(
  a: number,
  e: number,
  count: number,
): Array<{ x: number; y: number; nu: number; r: number }> {
  const p = a * (1 - e * e);
  const out: Array<{ x: number; y: number; nu: number; r: number }> = [];
  for (let i = 0; i < count; i++) {
    const nu = (i / count) * TWO_PI;
    const r = p / (1 + e * Math.cos(nu));
    out.push({ x: r * Math.cos(nu), y: r * Math.sin(nu), nu, r });
  }
  return out;
}
