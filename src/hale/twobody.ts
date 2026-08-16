/**
 * Two-body dynamics from Hale Ch. 2–3.
 * Port of Hale_Orbital.Twobody (Ada).
 */
import { SMALL_THRESHOLD } from "./constants";
import { type Vec3, cross, dot, mag, mag2 } from "./vectors";

export function specificEnergyState(r: Vec3, v: Vec3, mu: number): number {
  const rm = mag(r);
  if (rm <= 0 || mu <= 0) throw new Error("Invalid state for energy");
  return mag2(v) / 2 - mu / rm;
}

export function specificEnergySma(a: number, mu: number): number {
  if (Math.abs(a) <= SMALL_THRESHOLD || mu <= 0) {
    throw new Error("Invalid a/mu for energy");
  }
  return -mu / (2 * a);
}

export function angularMomentumVector(r: Vec3, v: Vec3): Vec3 {
  return cross(r, v);
}

export function angularMomentum(r: Vec3, v: Vec3): number {
  return mag(angularMomentumVector(r, v));
}

export function angularMomentumElements(a: number, e: number, mu: number): number {
  const p = a * (1 - e * e);
  return Math.sqrt(mu * p);
}

/** Hale Eq. 2.19 — v = sqrt(mu (2/r − 1/a)) */
export function visViva(r: number, a: number, mu: number): number {
  if (r <= 0 || Math.abs(a) <= SMALL_THRESHOLD || mu <= 0) {
    throw new Error("visViva: invalid arguments");
  }
  const inside = mu * (2 / r - 1 / a);
  if (inside < 0) throw new Error("visViva: unbound at this r/a");
  return Math.sqrt(inside);
}

export function circularVelocity(r: number, mu: number): number {
  if (r <= 0 || mu <= 0) throw new Error("circularVelocity: invalid arguments");
  return Math.sqrt(mu / r);
}

export function escapeVelocity(r: number, mu: number): number {
  if (r <= 0 || mu <= 0) throw new Error("escapeVelocity: invalid arguments");
  return Math.sqrt((2 * mu) / r);
}

/** Hale Eq. 2.24 — T = 2π sqrt(a³/μ) */
export function orbitalPeriod(a: number, mu: number): number {
  if (a <= 0 || mu <= 0) throw new Error("orbitalPeriod: invalid arguments");
  return 2 * Math.PI * Math.sqrt((a * a * a) / mu);
}

export function meanMotion(a: number, mu: number): number {
  if (a <= 0 || mu <= 0) throw new Error("meanMotion: invalid arguments");
  return Math.sqrt(mu / (a * a * a));
}

export function semiLatusRectum(a: number, e: number): number {
  return a * (1 - e * e);
}

export function periapsisDistance(a: number, e: number): number {
  return a * (1 - e);
}

export function apoapsisDistance(a: number, e: number): number {
  return a * (1 + e);
}

/** Hale Eq. 3.4 — r = p / (1 + e cos ν) */
export function radiusAtTrueAnomaly(p: number, e: number, nu: number): number {
  const den = 1 + e * Math.cos(nu);
  if (Math.abs(den) < SMALL_THRESHOLD) throw new Error("orbit equation singularity");
  return p / den;
}

export function semiMajorAxisFromRV(r: number, v: number, mu: number): number {
  const inv = 2 / r - (v * v) / mu;
  if (Math.abs(inv) < SMALL_THRESHOLD) throw new Error("parabolic SMA");
  return 1 / inv;
}

export function eccentricityVector(r: Vec3, v: Vec3, mu: number): Vec3 {
  const rm = mag(r);
  const v2 = mag2(v);
  const rv = dot(r, v);
  return [
    ((v2 - mu / rm) * r[0] - rv * v[0]) / mu,
    ((v2 - mu / rm) * r[1] - rv * v[1]) / mu,
    ((v2 - mu / rm) * r[2] - rv * v[2]) / mu,
  ];
}

export function eccentricityFromState(r: Vec3, v: Vec3, mu: number): number {
  return mag(eccentricityVector(r, v, mu));
}

export type OrbitKind = "circular" | "elliptical" | "parabolic" | "hyperbolic";

export function classifyOrbit(e: number): OrbitKind {
  if (e < 1e-10) return "circular";
  if (e < 1 - 1e-10) return "elliptical";
  if (Math.abs(e - 1) < 1e-10) return "parabolic";
  return "hyperbolic";
}
