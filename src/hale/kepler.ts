/**
 * Kepler equation (elliptic) — Hale Ch. 4 / Ada Hale_Orbital.Kepler.
 * Full hyperbolic / universal / Stumpff land in a later session.
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
