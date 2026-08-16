/**
 * Behind-the-scenes Hale run that writes a 2-minute sequence.
 * Imagine never sees a mood. It sees these numbers.
 */
import { MU_EARTH, R_EARTH, RAD_TO_DEG } from "./constants";
import { hohmannTransfer } from "./maneuvers";
import { visViva } from "./twobody";
import { solveKeplerElliptic, eccentricFromTrue, meanFromE } from "./kepler";

export const HOUSE_CLIP_SEC = 15;
export const HOUSE_CLIP_COUNT = 8;
export const HOUSE_RUNTIME_SEC = HOUSE_CLIP_SEC * HOUSE_CLIP_COUNT;

const R1 = R_EARTH + 300;
const R2 = 42_164;

function earthDiskDeg(rKm: number): number {
  return 2 * Math.asin(Math.min(1, R_EARTH / rKm)) * RAD_TO_DEG;
}

function radiusOnEllipse(nu: number, a: number, e: number): number {
  return (a * (1 - e * e)) / (1 + e * Math.cos(nu));
}

const h = hohmannTransfer(R1, R2, MU_EARTH);

/** Eight stations along the Hohmann ellipse. ν in radians. */
const STATIONS = [0, 0.09, 0.44, 1.22, 2.09, 2.79, 3.05, Math.PI];

export type HouseShot = {
  index: number;
  tStart: string;
  nuDeg: number;
  rKm: number;
  vKms: number;
  earthDeg: number;
  title: string;
  line: string;
  file?: string;
  still?: string;
  prompt: string;
};

function pad(i: number): string {
  const s = i * HOUSE_CLIP_SEC;
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
}

const TITLES = [
  "Gloves on the glass",
  "First burn",
  "The coast begins",
  "Midcourse",
  "The disk",
  "GEO twilight",
  "Second burn",
  "Hold",
];

const LINES = [
  "LEO sunrise. The planet is the cabin.",
  "Periapsis. The stack leans.",
  "Engine out. Nobody talks.",
  "Kepler turns M into ν. Earth halves.",
  "Apoapsis is still hours away. A marble is forming.",
  "The clock is the only moving thing.",
  "Circularize. Vis-viva closes.",
  "GEO. The climb is over.",
];

export const HOUSE_SHOTS: HouseShot[] = STATIONS.map((nu, i) => {
  const r = radiusOnEllipse(nu, h.aTransfer, h.eTransfer);
  const v = visViva(r, h.aTransfer, MU_EARTH);
  const earth = earthDiskDeg(r);
  const E = eccentricFromTrue(nu, h.eTransfer);
  const M = meanFromE(E, h.eTransfer);
  const n = i + 1;
  const fileName = String(n).padStart(2, "0");
  const arrived = n <= 3;
  return {
    index: n,
    tStart: pad(i),
    nuDeg: nu * RAD_TO_DEG,
    rKm: r,
    vKms: v,
    earthDeg: earth,
    title: TITLES[i]!,
    line: LINES[i]!,
    file: arrived ? `/films/001/clip-${fileName}.mp4` : undefined,
    still: arrived || n <= 2 ? `/films/001/still-${fileName}.jpg` : undefined,
    prompt: [
      `Photoreal IMAX space cinema, 16:9, copper dawn, quiet.`,
      TITLES[i],
      LINES[i],
      `True anomaly ${ (nu * RAD_TO_DEG).toFixed(1) } degrees on a Hohmann transfer.`,
      `Distance from Earth's center ${r.toFixed(0)} km. Speed ${v.toFixed(3)} km/s.`,
      `Earth subtends ${earth.toFixed(1)} degrees — draw that scale, not a generic planet.`,
      `No HUD, no text, no numbers on screen, no logos.`,
    ].join(" "),
  };
});

export const HOUSE_TELEMETRY = {
  r1: R1,
  r2: R2,
  aTransfer: h.aTransfer,
  eTransfer: h.eTransfer,
  deltaV1: h.deltaV1,
  deltaV2: h.deltaV2,
  transferHours: h.transferTime / 3600,
  keplerMid: (() => {
    const M = Math.PI / 2;
    const E = solveKeplerElliptic(M, h.eTransfer);
    return { M, E };
  })(),
};

export const HOUSE_FILM = {
  id: "001",
  title: "The Climb",
  runtime: "2:00",
  logline: "LEO to GEO. Two burns. Hale’s vis-viva does the work.",
  arrived: HOUSE_SHOTS.filter((s) => s.file).length,
  total: HOUSE_CLIP_COUNT,
  shots: HOUSE_SHOTS,
  telemetry: HOUSE_TELEMETRY,
};

export function houseTweet(): string {
  const t = HOUSE_TELEMETRY;
  return [
    `The Climb — 2 minutes.`,
    `LEO → GEO. Δv₁ ${t.deltaV1.toFixed(2)} km/s · coast ${t.transferHours.toFixed(2)} h · Δv₂ ${t.deltaV2.toFixed(2)} km/s.`,
    `Simmed in Hale. Shot from the numbers.`,
    `#HaleGrok`,
  ].join("\n");
}
