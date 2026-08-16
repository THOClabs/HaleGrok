/**
 * Impulsive maneuvers from Hale Ch. 6.
 * Port of Hale_Orbital.Maneuvers (Ada).
 */
import { PI } from "./constants";
import { circularVelocity } from "./twobody";

export type HohmannResult = {
  deltaV1: number;
  deltaV2: number;
  totalDeltaV: number;
  transferTime: number;
  aTransfer: number;
  eTransfer: number;
  vCirc1: number;
  vCirc2: number;
  vTrans1: number;
  vTrans2: number;
};

export function hohmannTransfer(
  rInitial: number,
  rFinal: number,
  mu: number,
): HohmannResult {
  if (rInitial <= 0 || rFinal <= 0 || mu <= 0) {
    throw new Error("Hohmann: radii and mu must be positive");
  }
  const aTrans = (rInitial + rFinal) / 2;
  const vCirc1 = circularVelocity(rInitial, mu);
  const vCirc2 = circularVelocity(rFinal, mu);
  const vTrans1 = Math.sqrt(mu * (2 / rInitial - 1 / aTrans));
  const vTrans2 = Math.sqrt(mu * (2 / rFinal - 1 / aTrans));
  const deltaV1 = Math.abs(vTrans1 - vCirc1);
  const deltaV2 = Math.abs(vCirc2 - vTrans2);
  const eTransfer =
    rInitial < rFinal
      ? (rFinal - rInitial) / (rFinal + rInitial)
      : (rInitial - rFinal) / (rInitial + rFinal);
  return {
    deltaV1,
    deltaV2,
    totalDeltaV: deltaV1 + deltaV2,
    transferTime: PI * Math.sqrt((aTrans * aTrans * aTrans) / mu),
    aTransfer: aTrans,
    eTransfer,
    vCirc1,
    vCirc2,
    vTrans1,
    vTrans2,
  };
}

export type BiellipticResult = {
  deltaV1: number;
  deltaV2: number;
  deltaV3: number;
  totalDeltaV: number;
  transferTime: number;
  rIntermediate: number;
};

export function biellipticTransfer(
  rInitial: number,
  rFinal: number,
  rIntermediate: number,
  mu: number,
): BiellipticResult {
  if (rInitial <= 0 || rFinal <= 0 || rIntermediate <= 0 || mu <= 0) {
    throw new Error("Bielliptic: radii and mu must be positive");
  }
  const a1 = (rInitial + rIntermediate) / 2;
  const a2 = (rIntermediate + rFinal) / 2;
  const vCirc1 = circularVelocity(rInitial, mu);
  const vCirc2 = circularVelocity(rFinal, mu);
  const v1a = Math.sqrt(mu * (2 / rInitial - 1 / a1));
  const v1b = Math.sqrt(mu * (2 / rIntermediate - 1 / a1));
  const v2a = Math.sqrt(mu * (2 / rIntermediate - 1 / a2));
  const v2b = Math.sqrt(mu * (2 / rFinal - 1 / a2));
  const deltaV1 = Math.abs(v1a - vCirc1);
  const deltaV2 = Math.abs(v2a - v1b);
  const deltaV3 = Math.abs(vCirc2 - v2b);
  const t1 = PI * Math.sqrt((a1 * a1 * a1) / mu);
  const t2 = PI * Math.sqrt((a2 * a2 * a2) / mu);
  return {
    deltaV1,
    deltaV2,
    deltaV3,
    totalDeltaV: deltaV1 + deltaV2 + deltaV3,
    transferTime: t1 + t2,
    rIntermediate,
  };
}

/** Hale §6.3 — bi-elliptic beats Hohmann when r2/r1 > 11.94 */
export function biellipticIsEfficient(rInitial: number, rFinal: number): boolean {
  const ratio = Math.max(rInitial, rFinal) / Math.min(rInitial, rFinal);
  return ratio > 11.94;
}

export function simplePlaneChange(deltaI: number, v: number): number {
  return 2 * v * Math.sin(Math.abs(deltaI) / 2);
}

export function escapeDeltaV(r: number, mu: number): number {
  return circularVelocity(r, mu) * (Math.SQRT2 - 1);
}
