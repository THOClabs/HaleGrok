/**
 * Circular Restricted Three-Body Problem.
 * Port of Hale_Orbital.Threebody (Ada) + python/three-body-extension oracle.
 * Hale Ch. 10, Szebehely.
 */
import { A_MOON, AU, MU_EARTH, MU_JUPITER, MU_MOON, MU_ROUTH_CRITICAL, MU_SUN } from "./constants";

export type LagrangeId = "L1" | "L2" | "L3" | "L4" | "L5";

export type ThreebodySystem = {
  name: string;
  mu1: number;
  mu2: number;
  distance: number;
  massRatio: number;
};

export type NormalizedState = {
  x: number;
  y: number;
  z: number;
  vx: number;
  vy: number;
  vz: number;
};

export type LagrangeResult = {
  point: LagrangeId;
  x: number;
  y: number;
  distanceKm: number;
  jacobi: number;
  converged: boolean;
};

export const EARTH_MOON: ThreebodySystem = {
  name: "Earth-Moon",
  mu1: 398600.4418,
  mu2: 4902.8,
  distance: 384400.0,
  massRatio: 0.012150583916325,
};

export const SUN_EARTH: ThreebodySystem = {
  name: "Sun-Earth",
  mu1: 132712440018.0,
  mu2: 398600.4418,
  distance: 149597870.7,
  massRatio: 3.0034806424871e-6,
};

export const SUN_JUPITER: ThreebodySystem = {
  name: "Sun-Jupiter",
  mu1: 132712440018.0,
  mu2: 126686534.0,
  distance: 778570000.0,
  massRatio: 9.5368388281602e-4,
};

const NEWTON_TOL = 1e-12;
const NEWTON_MAX = 100;

function newtonGamma(
  gamma0: number,
  f: (g: number) => number,
  fp: (g: number) => number,
): { gamma: number; converged: boolean } {
  let gamma = gamma0;
  for (let i = 0; i < NEWTON_MAX; i++) {
    const deriv = fp(gamma);
    if (Math.abs(deriv) < 1e-15) return { gamma, converged: false };
    const delta = f(gamma) / deriv;
    gamma -= delta;
    if (Math.abs(delta) < NEWTON_TOL) return { gamma, converged: true };
  }
  return { gamma, converged: false };
}

/** Ada Hale_Orbital.Threebody.Compute_Lagrange_Point */
export function computeLagrangePoint(
  system: ThreebodySystem,
  point: LagrangeId,
): LagrangeResult {
  const mu = system.massRatio;
  let x = 0;
  let y = 0;
  let converged = false;

  if (point === "L1") {
    const g0 = Math.cbrt(mu / 3);
    const { gamma, converged: ok } = newtonGamma(
      g0,
      (g) => {
        const g2 = g * g;
        const g3 = g2 * g;
        const g4 = g3 * g;
        const g5 = g4 * g;
        return g5 - (3 - mu) * g4 + (3 - 2 * mu) * g3 - mu * g2 + 2 * mu * g - mu;
      },
      (g) => {
        const g2 = g * g;
        const g3 = g2 * g;
        const g4 = g3 * g;
        return 5 * g4 - 4 * (3 - mu) * g3 + 3 * (3 - 2 * mu) * g2 - 2 * mu * g + 2 * mu;
      },
    );
    x = 1 - mu - gamma;
    y = 0;
    converged = ok;
  } else if (point === "L2") {
    const g0 = Math.cbrt(mu / 3);
    const { gamma, converged: ok } = newtonGamma(
      g0,
      (g) => {
        const g2 = g * g;
        const g3 = g2 * g;
        const g4 = g3 * g;
        const g5 = g4 * g;
        return g5 + (3 - mu) * g4 + (3 - 2 * mu) * g3 - mu * g2 - 2 * mu * g - mu;
      },
      (g) => {
        const g2 = g * g;
        const g3 = g2 * g;
        const g4 = g3 * g;
        return 5 * g4 + 4 * (3 - mu) * g3 + 3 * (3 - 2 * mu) * g2 - 2 * mu * g - 2 * mu;
      },
    );
    x = 1 - mu + gamma;
    y = 0;
    converged = ok;
  } else if (point === "L3") {
    const g0 = 1 - (7 * mu) / 12;
    const { gamma, converged: ok } = newtonGamma(
      g0,
      (g) => {
        const g2 = g * g;
        const g3 = g2 * g;
        const g4 = g3 * g;
        const g5 = g4 * g;
        return (
          g5 +
          (2 + mu) * g4 +
          (1 + 2 * mu) * g3 -
          (1 - mu) * g2 -
          2 * (1 - mu) * g -
          (1 - mu)
        );
      },
      (g) => {
        const g2 = g * g;
        const g3 = g2 * g;
        const g4 = g3 * g;
        return (
          5 * g4 +
          4 * (2 + mu) * g3 +
          3 * (1 + 2 * mu) * g2 -
          2 * (1 - mu) * g -
          2 * (1 - mu)
        );
      },
    );
    x = -mu - gamma;
    y = 0;
    converged = ok;
  } else if (point === "L4") {
    x = 0.5 - mu;
    y = Math.sqrt(3) / 2;
    converged = true;
  } else {
    x = 0.5 - mu;
    y = -Math.sqrt(3) / 2;
    converged = true;
  }

  const jacobi = jacobiConstant({ x, y, z: 0, vx: 0, vy: 0, vz: 0 }, mu);
  return {
    point,
    x,
    y,
    distanceKm: Math.hypot(x, y) * system.distance,
    jacobi,
    converged,
  };
}

export function computeAllLagrange(system: ThreebodySystem): LagrangeResult[] {
  return (["L1", "L2", "L3", "L4", "L5"] as LagrangeId[]).map((p) =>
    computeLagrangePoint(system, p),
  );
}

export function r1(x: number, y: number, z: number, mu: number): number {
  return Math.hypot(x + mu, y, z);
}

export function r2(x: number, y: number, z: number, mu: number): number {
  return Math.hypot(x - (1 - mu), y, z);
}

/** Ω = (x² + y²)/2 + (1−μ)/r₁ + μ/r₂ */
export function pseudoPotential(x: number, y: number, z: number, mu: number): number {
  return 0.5 * (x * x + y * y) + (1 - mu) / r1(x, y, z, mu) + mu / r2(x, y, z, mu);
}

export function jacobiConstant(state: NormalizedState, mu: number): number {
  const v2 = state.vx * state.vx + state.vy * state.vy + state.vz * state.vz;
  return 2 * pseudoPotential(state.x, state.y, state.z, mu) - v2;
}

function omegaPartials(state: NormalizedState, mu: number) {
  const { x, y, z } = state;
  const d1 = r1(x, y, z, mu);
  const d2 = r2(x, y, z, mu);
  const d1c = d1 * d1 * d1;
  const d2c = d2 * d2 * d2;
  return {
    ox: x - ((1 - mu) * (x + mu)) / d1c - (mu * (x - 1 + mu)) / d2c,
    oy: y - ((1 - mu) * y) / d1c - (mu * y) / d2c,
    oz: -((1 - mu) * z) / d1c - (mu * z) / d2c,
  };
}

export function acceleration(state: NormalizedState, mu: number) {
  const { ox, oy, oz } = omegaPartials(state, mu);
  return {
    ax: 2 * state.vy + ox,
    ay: -2 * state.vx + oy,
    az: oz,
  };
}

function deriv(state: NormalizedState, mu: number): NormalizedState {
  const a = acceleration(state, mu);
  return {
    x: state.vx,
    y: state.vy,
    z: state.vz,
    vx: a.ax,
    vy: a.ay,
    vz: a.az,
  };
}

function addScaled(a: NormalizedState, b: NormalizedState, s: number): NormalizedState {
  return {
    x: a.x + b.x * s,
    y: a.y + b.y * s,
    z: a.z + b.z * s,
    vx: a.vx + b.vx * s,
    vy: a.vy + b.vy * s,
    vz: a.vz + b.vz * s,
  };
}

/** Fixed-step RK4 — Ada Integration_Method.RK4 */
export function propagateRk4(
  initial: NormalizedState,
  mu: number,
  tFinal: number,
  step = 0.001,
): { final: NormalizedState; samples: NormalizedState[]; jacobiResidual: number } {
  if (tFinal <= 0) throw new Error("propagateRk4: T_Final must be positive");
  const samples: NormalizedState[] = [{ ...initial }];
  let state = { ...initial };
  let t = 0;
  while (t < tFinal - 1e-15) {
    const h = Math.min(step, tFinal - t);
    const k1 = deriv(state, mu);
    const k2 = deriv(addScaled(state, k1, h / 2), mu);
    const k3 = deriv(addScaled(state, k2, h / 2), mu);
    const k4 = deriv(addScaled(state, k3, h), mu);
    state = {
      x: state.x + (h / 6) * (k1.x + 2 * k2.x + 2 * k3.x + k4.x),
      y: state.y + (h / 6) * (k1.y + 2 * k2.y + 2 * k3.y + k4.y),
      z: state.z + (h / 6) * (k1.z + 2 * k2.z + 2 * k3.z + k4.z),
      vx: state.vx + (h / 6) * (k1.vx + 2 * k2.vx + 2 * k3.vx + k4.vx),
      vy: state.vy + (h / 6) * (k1.vy + 2 * k2.vy + 2 * k3.vy + k4.vy),
      vz: state.vz + (h / 6) * (k1.vz + 2 * k2.vz + 2 * k3.vz + k4.vz),
    };
    t += h;
    if (samples.length < 480) samples.push({ ...state });
  }
  const c0 = jacobiConstant(initial, mu);
  const c1 = jacobiConstant(state, mu);
  return { final: state, samples, jacobiResidual: Math.abs(c1 - c0) };
}

export function isL4L5Stable(mu: number): boolean {
  return mu < MU_ROUTH_CRITICAL;
}

export function primaryPositions(system: ThreebodySystem) {
  const mu = system.massRatio;
  return {
    p1: { x: -mu, y: 0 },
    p2: { x: 1 - mu, y: 0 },
  };
}

export function dimensionalKm(norm: number, system: ThreebodySystem): number {
  return norm * system.distance;
}

export function timeUnitSeconds(system: ThreebodySystem): number {
  const n = Math.sqrt((system.mu1 + system.mu2) / system.distance ** 3);
  return 1 / n;
}

export { MU_EARTH, MU_MOON, MU_SUN, MU_JUPITER, A_MOON, AU };
