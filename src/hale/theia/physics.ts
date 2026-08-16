/**
 * Theia / Terra numbers Hale can stand behind.
 * Hydrodynamics, mixing, and SPH hours are out of scope — labeled when we touch them.
 */
import {
  AU,
  M_EARTH,
  M_MOON,
  M_SUN,
  MU_EARTH,
  MU_MOON,
  MU_ROUTH_CRITICAL,
  MU_SUN,
  R_EARTH,
  R_MARS,
  R_MOON,
} from "../constants";
import { escapeVelocity } from "../twobody";

/** Canonical Mars-class Theia (Hartmann/Davis, Cameron/Ward). */
export const THEIA_MASS_RATIO = 0.1;
export const M_THEIA = THEIA_MASS_RATIO * M_EARTH;
export const MU_THEIA = THEIA_MASS_RATIO * MU_EARTH;
export const R_THEIA = R_MARS;

/** Literature oracles we match, not invent. */
export const ORACLE = {
  vInfMaxKms: 4,
  vImpactMinKms: 9.3,
  impactAngleDeg: 45,
  postImpactDayHours: 5,
  moonAgeGa: 4.5,
  rocheFluidEarthRadii: 2.9,
  theiaMassThreshold: 0.1,
};

export function meanDensityKgM3(massKg: number, radiusKm: number): number {
  const r = radiusKm * 1000;
  return massKg / ((4 / 3) * Math.PI * r * r * r);
}

export const RHO_EARTH = meanDensityKgM3(M_EARTH, R_EARTH);
export const RHO_MOON = meanDensityKgM3(M_MOON, R_MOON);

/** Hill sphere of the secondary about the primary. a * (m2 / 3 m1)^{1/3} */
export function hillSphereKm(aKm: number, mSecondary: number, mPrimary: number): number {
  return aKm * Math.cbrt(mSecondary / (3 * mPrimary));
}

/** Fluid Roche: 2.44 R_p (ρ_p / ρ_s)^{1/3} */
export function rocheFluidKm(radiusPrimaryKm: number, rhoP: number, rhoS: number): number {
  return 2.44 * radiusPrimaryKm * Math.cbrt(rhoP / rhoS);
}

/** Rigid Roche: 1.26 R_p (ρ_p / ρ_s)^{1/3} */
export function rocheRigidKm(radiusPrimaryKm: number, rhoP: number, rhoS: number): number {
  return 1.26 * radiusPrimaryKm * Math.cbrt(rhoP / rhoS);
}

/** Mutual escape at contact: sqrt(2(μ1+μ2)/(R1+R2)) */
export function mutualEscapeKms(mu1: number, mu2: number, r1: number, r2: number): number {
  return Math.sqrt((2 * (mu1 + mu2)) / (r1 + r2));
}

/** v_imp = sqrt(v∞² + v_esc,mutual²) */
export function impactSpeedKms(vInf: number, vEscMutual: number): number {
  return Math.sqrt(vInf * vInf + vEscMutual * vEscMutual);
}

export function terraEscapeSurface(): number {
  return escapeVelocity(R_EARTH, MU_EARTH);
}

/** Sun–Terra–Theia mass parameter if Theia is a third mass (not CR3BP). */
export function theiaSunTerraMu(): number {
  return M_THEIA / (M_SUN + M_EARTH + M_THEIA);
}

/** Restricted μ of Theia about Terra (two comparable rocks). */
export function theiaTerraMu(): number {
  return M_THEIA / (M_EARTH + M_THEIA);
}

export function routhHolds(mu: number): boolean {
  return mu < MU_ROUTH_CRITICAL;
}

export const PHYSICS = {
  THEIA_MASS_RATIO,
  M_THEIA,
  MU_THEIA,
  R_THEIA,
  RHO_EARTH,
  RHO_MOON,
  ORACLE,
  hillTerraKm: hillSphereKm(AU, M_EARTH, M_SUN),
  rocheFluidKm: rocheFluidKm(R_EARTH, RHO_EARTH, RHO_MOON),
  rocheRigidKm: rocheRigidKm(R_EARTH, RHO_EARTH, RHO_MOON),
  vEscTerra: terraEscapeSurface(),
  vEscMutual: mutualEscapeKms(MU_EARTH, MU_THEIA, R_EARTH, R_THEIA),
  theiaTerraMu: theiaTerraMu(),
  theiaSunTerraMu: theiaSunTerraMu(),
};
