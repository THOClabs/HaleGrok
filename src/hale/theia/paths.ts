import { AU, MU_EARTH } from "../constants";
import { computeLagrangePoint, propagateRk4, SUN_EARTH } from "../threebody";
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

/** Hyperbola about Terra, km. ν from far inbound to near periapsis. */
export function approachHyperbola() {
  const vInf = 4;
  const rp = PHYSICS.vEscMutual > 0 ? 9774.337 : 9774;
  const a = -MU_EARTH / (vInf * vInf);
  const e = 1 + (rp * vInf * vInf) / MU_EARTH;
  const p = rp * (1 + e);
  const nus: number[] = [];
  for (let d = -130; d <= -8; d += 2) nus.push((d * Math.PI) / 180);
  const points = nus.map((nu) => {
    const r = p / (1 + e * Math.cos(nu));
    return { x: r * Math.cos(nu), y: r * Math.sin(nu), r };
  });
  return { a, e, rp, vInf, p, points };
}

export const HILL_AU = PHYSICS.hillTerraKm / AU;
export const CONTACT_KM = 9774.337;
