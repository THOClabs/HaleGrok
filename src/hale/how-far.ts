/**
 * How Far — 2-minute documentary written by Hale at scales we do not feel.
 * No cabin. No gloves. The Ada three-body + Hohmann numbers only.
 */
import { AU, MU_SUN, R_EARTH } from "./constants";
import { hohmannTransfer } from "./maneuvers";
import {
  computeLagrangePoint,
  EARTH_MOON,
  SUN_EARTH,
  SUN_JUPITER,
  r1,
  r2,
} from "./threebody";

export const HOW_FAR_CLIP_SEC = 15;
export const HOW_FAR_COUNT = 8;

const em = {
  L1: computeLagrangePoint(EARTH_MOON, "L1"),
  L2: computeLagrangePoint(EARTH_MOON, "L2"),
  L3: computeLagrangePoint(EARTH_MOON, "L3"),
  L4: computeLagrangePoint(EARTH_MOON, "L4"),
  L5: computeLagrangePoint(EARTH_MOON, "L5"),
};
const se = {
  L1: computeLagrangePoint(SUN_EARTH, "L1"),
  L2: computeLagrangePoint(SUN_EARTH, "L2"),
  L3: computeLagrangePoint(SUN_EARTH, "L3"),
};
const sj = {
  L4: computeLagrangePoint(SUN_JUPITER, "L4"),
};

const mars = hohmannTransfer(AU, 1.523679 * AU, MU_SUN);
const marsDays = mars.transferTime / 86400;

/** Hill sphere of Earth about the Sun, km */
const earthHillKm = AU * Math.cbrt(SUN_EARTH.massRatio / 3);

export const HOW_FAR_NUMBERS = {
  moonKm: EARTH_MOON.distance,
  moonEarthRadii: EARTH_MOON.distance / R_EARTH,
  emL1Km: r1(em.L1.x, 0, 0, EARTH_MOON.massRatio) * EARTH_MOON.distance,
  emL1FromMoonKm: r2(em.L1.x, 0, 0, EARTH_MOON.massRatio) * EARTH_MOON.distance,
  emL4Km: em.L4.distanceKm,
  emMu: EARTH_MOON.massRatio,
  emL1Jacobi: em.L1.jacobi,
  seL1Km: r2(se.L1.x, 0, 0, SUN_EARTH.massRatio) * AU,
  seL2Km: r2(se.L2.x, 0, 0, SUN_EARTH.massRatio) * AU,
  seL1Au: r2(se.L1.x, 0, 0, SUN_EARTH.massRatio),
  seL2Au: r2(se.L2.x, 0, 0, SUN_EARTH.massRatio),
  earthHillKm,
  earthHillAu: earthHillKm / AU,
  sjL4Km: sj.L4.distanceKm,
  sjL4Au: sj.L4.distanceKm / AU,
  marsA_AU: mars.aTransfer / AU,
  marsE: mars.eTransfer,
  marsDays,
  marsDv1: mars.deltaV1,
  marsDv2: mars.deltaV2,
  seMu: SUN_EARTH.massRatio,
};

export type HowFarShot = {
  index: number;
  tStart: string;
  title: string;
  line: string;
  finding: string;
  prompt: string;
  wire: string;
  still?: string;
  file?: string;
};

function t(i: number): string {
  const s = i * HOW_FAR_CLIP_SEC;
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
}

const n = HOW_FAR_NUMBERS;

export const HOW_FAR_SHOTS: HowFarShot[] = [
  {
    index: 1,
    tStart: t(0),
    title: "Two masses",
    line: "Earth and the Moon, drawn at Hale’s distance. Almost nothing between them.",
    finding: `${n.moonKm.toFixed(0)} km · ${n.moonEarthRadii.toFixed(1)} Earth radii`,
    wire: "/films/002/wire-01.png",
    still: "/films/002/still-01.jpg",
    file: "/films/002/clip-01.mp4",
    prompt:
      "Science documentary, IMAX astronomy, no people, no spacecraft cabin. Two real bodies in a black field: Earth small, the Moon a pale coin far away, the true 384400 km emptiness between them felt as darkness. Slow camera drift. No HUD, no text, no labels.",
  },
  {
    index: 2,
    tStart: t(1),
    title: "Five points",
    line: "In the rotating frame the empty room has five places where gravity cancels.",
    finding: `μ = ${n.emMu.toExponential(3)} · Earth–Moon CR3BP`,
    wire: "/films/002/wire-02.png",
    still: "/films/002/still-02.jpg",
    file: "/films/002/clip-02.mp4",
    prompt:
      "Science documentary, IMAX astronomy, no people. The Earth-Moon rotating frame as a vast dark plane. Two glowing bodies. Five faint Lagrange points like cold stars sitting in the geometry — three on the line, two at equilateral triangles. Slow orbital rotation of the frame. No text, no HUD.",
  },
  {
    index: 3,
    tStart: t(2),
    title: "The saddle",
    line: "L1. A door that is only a number until you stand in it.",
    finding: `Earth–Moon L1 · ${n.emL1Km.toFixed(0)} km from Earth · C = ${n.emL1Jacobi.toFixed(4)}`,
    wire: "/films/002/wire-03.png",
    still: "/films/002/still-03.jpg",
    file: "/films/002/clip-03.mp4",
    prompt:
      "Science documentary, IMAX astronomy, no people, no ship interiors. A dark saddle of empty space between Earth and the Moon — Earth large and blue to one side, Moon small and bone to the other, the camera floating in the L1 gap where both pulls cancel. Physical sunlight. No text.",
  },
  {
    index: 4,
    tStart: t(3),
    title: "The triangles",
    line: "L4 and L5. Sixty degrees. Routh said they hold if μ is small enough.",
    finding: `L4 / L5 · 60° · ${n.emL4Km.toFixed(0)} km from each primary`,
    wire: "/films/002/wire-04.png",
    still: "/films/002/still-04.jpg",
    file: "/films/002/clip-04.mp4",
    prompt:
      "Science documentary, IMAX astronomy, no people. Looking down on the Earth-Moon plane from high above. A perfect equilateral triangle of darkness: Earth, Moon, and a faint concentration of dust at the leading triangular point L4. Slow rotation. No text, no HUD.",
  },
  {
    index: 5,
    tStart: t(4),
    title: "Leave the Moon",
    line: "Pull back until the Moon is a pixel. The Sun now owns the problem.",
    finding: `Sun–Earth L1 · ${n.seL1Km.toFixed(0)} km · ${n.seL1Au.toFixed(4)} AU`,
    wire: "/films/002/wire-05.png",
    still: "/films/002/still-05.jpg",
    file: "/films/002/clip-05.mp4",
    prompt:
      "Science documentary, IMAX astronomy, no people. Extreme scale pullback: the Earth-Moon pair shrinks to a double spark. The Sun dominates. A tiny unmarked point 1.5 million km sunward of Earth — L1 — hanging in the solar wind. Vast black. No text.",
  },
  {
    index: 6,
    tStart: t(5),
    title: "The night that never ends",
    line: "L2, anti-sunward. A telescope sits in a halo you cannot see from home.",
    finding: `Sun–Earth L2 · ${n.seL2Km.toFixed(0)} km · ${n.seL2Au.toFixed(4)} AU`,
    wire: "/films/002/wire-06.png",
    still: "/films/002/still-06.jpg",
    file: "/films/002/clip-06.mp4",
    prompt:
      "Science documentary, IMAX astronomy, no people, no close-up hardware. Deep space anti-sunward of Earth. Earth is a small blue disk, the Sun a distant glare beyond it. At L2, 1.5 million km further out, a nearly invisible point in a slow halo. Infrared-cold palette. No text, no HUD.",
  },
  {
    index: 7,
    tStart: t(6),
    title: "Five astronomical units",
    line: "Sun–Jupiter L4. A camp of asteroids sharing Jupiter’s year.",
    finding: `Sun–Jupiter L4 · ${n.sjL4Au.toFixed(2)} AU · ${n.sjL4Km.toExponential(3)} km`,
    wire: "/films/002/wire-07.png",
    still: "/films/002/still-07.jpg",
    file: "/films/002/clip-07.mp4",
    prompt:
      "Science documentary, IMAX astronomy, no people. The inner solar system from far above the ecliptic. Sun, a thin Earth orbit, Jupiter a bright point on a huge circle, and at 60 degrees ahead a loose cloud of Trojan asteroids — faint, real, sparse. Scale that feels wrong. No text.",
  },
  {
    index: 8,
    tStart: t(7),
    title: "The cheap ellipse",
    line: "Earth to Mars is one Hohmann. Vis-viva does the eight months.",
    finding: `a = ${n.marsA_AU.toFixed(3)} AU · e = ${n.marsE.toFixed(3)} · ${n.marsDays.toFixed(1)} days · Δv ${ (n.marsDv1+n.marsDv2).toFixed(2) } km/s`,
    wire: "/films/002/wire-08.png",
    still: "/films/002/still-08.jpg",
    file: "/films/002/clip-08.mp4",
    prompt:
      "Science documentary, IMAX astronomy, no people, no crew. Looking down on the solar system: a thin Hohmann transfer ellipse touching Earth's orbit and Mars's orbit, a single silent path 259 days long. Sun at one focus. Empty black between the lines. No text, no HUD.",
  },
];

export const HOW_FAR = {
  id: "002",
  title: "How Far",
  runtime: "2:00",
  logline: "Hale’s three-body problem and one Hohmann, at scales the body cannot hold.",
  arrived: HOW_FAR_SHOTS.filter((s) => s.file).length,
  total: HOW_FAR_COUNT,
  shots: HOW_FAR_SHOTS,
  numbers: HOW_FAR_NUMBERS,
};

export function howFarTweet(): string {
  return [
    `How Far — 2 minutes.`,
    `Earth–Moon L1 ${n.emL1Km.toFixed(0)} km. Sun–Earth L2 ${n.seL2Au.toFixed(3)} AU. Mars in ${n.marsDays.toFixed(0)} days.`,
    `Hale three-body + Hohmann. No cabin.`,
    `#HaleGrok`,
  ].join("\n");
}
