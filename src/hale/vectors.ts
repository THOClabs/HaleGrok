/** 3-vector ops ported from Hale_Orbital.Vectors. */
export type Vec3 = [number, number, number];

export const ZERO: Vec3 = [0, 0, 0];
export const UNIT_X: Vec3 = [1, 0, 0];
export const UNIT_Y: Vec3 = [0, 1, 0];
export const UNIT_Z: Vec3 = [0, 0, 1];

export function add(a: Vec3, b: Vec3): Vec3 {
  return [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
}

export function sub(a: Vec3, b: Vec3): Vec3 {
  return [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
}

export function scale(a: Vec3, s: number): Vec3 {
  return [a[0] * s, a[1] * s, a[2] * s];
}

export function dot(a: Vec3, b: Vec3): number {
  return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

export function cross(a: Vec3, b: Vec3): Vec3 {
  return [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  ];
}

export function mag2(a: Vec3): number {
  return dot(a, a);
}

export function mag(a: Vec3): number {
  return Math.sqrt(mag2(a));
}

export function normalize(a: Vec3): Vec3 {
  const m = mag(a);
  if (m < 1e-15) throw new Error("Cannot normalize a near-zero vector");
  return scale(a, 1 / m);
}

export function finite(a: Vec3): boolean {
  return a.every((x) => Number.isFinite(x));
}
