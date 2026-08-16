import { A_MOON, AU, MU_EARTH, R_EARTH } from "../constants";
import { computeLagrangePoint, EARTH_MOON, propagateRk4, SUN_EARTH } from "../threebody";
import { PHYSICS } from "./physics";

export function wanderPath() {
  const L4 = computeLagrangePoint(SUN_EARTH, "L4");
  const kick = { x: L4.x + 0.002, y: L4.y, z: 0, vx: 0, vy: 0.001, vz: 0 };
  const run = propagateRk4(kick, SUN_EARTH.massRatio, 2.5, 0.002);
  return {
    L4: { x: L4.x, y: L4.y },
    points: run.samples.filter((_, i) => i % 5 === 0).map((s) => ({ x: s.x, y: s.y })),
    residual: run.jacobiResidual,
  };
}

export function approachHyperbola() {
  const vInf = 4;
  const rp = 9774.337;
  const a = -MU_EARTH / (vInf * vInf);
  const e = 1 + (rp * vInf * vInf) / MU_EARTH;
  const p = rp * (1 + e);
  const points = [] as Array<{ x: number; y: number; r: number }>;
  for (let d = -130; d <= -8; d += 2) {
    const nu = (d * Math.PI) / 180;
    const r = p / (1 + e * Math.cos(nu));
    points.push({ x: r * Math.cos(nu), y: r * Math.sin(nu), r });
  }
  return { a, e, rp, vInf, p, points };
}

/** 45° graze: contact at r=9774 km, h = r v sinθ. */
export function grazePath() {
  const r = 9774.337;
  const theta = Math.PI / 4;
  const b = 12776.959;
  const contact = { x: r * Math.cos(theta), y: r * Math.sin(theta) };
  const points = [] as Array<{ x: number; y: number }>;
  for (let s = 1; s >= 0; s -= 0.02) {
    points.push({
      x: contact.x - (1 - s) * 42000 * Math.cos(theta) + b * 0.15 * s,
      y: contact.y - (1 - s) * 42000 * Math.sin(theta) + b * (1 - 0.4 * s),
    });
  }
  points.push(contact);
  return { r, theta, b, contact, points };
}

export function earthMoon() {
  const L1 = computeLagrangePoint(EARTH_MOON, "L1");
  const L4 = computeLagrangePoint(EARTH_MOON, "L4");
  return {
    mu: EARTH_MOON.massRatio,
    earth: { x: -EARTH_MOON.massRatio, y: 0 },
    moon: { x: 1 - EARTH_MOON.massRatio, y: 0 },
    L1: { x: L1.x, y: L1.y },
    L4: { x: L4.x, y: L4.y },
  };
}

export const HILL_AU = PHYSICS.hillTerraKm / AU;
export const CONTACT_KM = 9774.337;
export const ROCHE_KM = 2.879354389745843 * R_EARTH;
export const LUNA_KM = A_MOON;
export const R3 = 3 * R_EARTH;
export const R5 = 5 * R_EARTH;
