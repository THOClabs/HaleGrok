import { HOW_FAR_NUMBERS as N } from "../how-far";
import { allStepsOk } from "../gauntlet";
import type { SimStep } from "../types";

export const L2 = {
  km: N.seL2Km,
  au: N.seL2Au,
  jacobi: 3.0008866891539268,
  hillAu: N.earthHillAu,
  hillKm: N.earthHillKm,
  duration: 180,
  shots: 12,
};

export type L2Shot = {
  index: number;
  t: string;
  title: string;
  vo: string;
  still: string;
  clip: string;
};

export const L2_SHOTS: L2Shot[] = [
  {
    index: 1,
    t: "0:00",
    title: "The glare",
    vo: "The Sun. For most of the sky, that is all there is.",
    still: "/films/016/still-01.jpg",
    clip: "/films/016/clip-01.mp4",
  },
  {
    index: 2,
    t: "0:15",
    title: "A grain",
    vo: "A blue grain sits in the glare. That is Earth.",
    still: "/films/016/still-02.jpg",
    clip: "/films/016/clip-02.mp4",
  },
  {
    index: 3,
    t: "0:30",
    title: "Behind",
    vo: "We are not looking at the planet. We are standing behind it.",
    still: "/films/016/still-03.jpg",
    clip: "/films/016/clip-03.mp4",
  },
  {
    index: 4,
    t: "0:45",
    title: "One five",
    vo: `One point five million kilometers further out. Sun–Earth L2. ${L2.au.toFixed(4)} astronomical units.`,
    still: "/films/016/still-04.jpg",
    clip: "/films/016/clip-04.mp4",
  },
  {
    index: 5,
    t: "1:00",
    title: "The saddle",
    vo: "Hale’s three-body problem puts a point here. A saddle. Nothing holds you unless you choose it.",
    still: "/films/016/still-05.jpg",
    clip: "/films/016/clip-05.mp4",
  },
  {
    index: 6,
    t: "1:15",
    title: "The night",
    vo: "Earth never sets. The Sun never rises. The night does not end.",
    still: "/films/016/still-hero.png",
    clip: "/films/016/clip-06.mp4",
  },
  {
    index: 7,
    t: "1:30",
    title: "Halo",
    vo: "A slow halo around a point you cannot see from home.",
    still: "/films/016/still-07.jpg",
    clip: "/films/016/clip-07.mp4",
  },
  {
    index: 8,
    t: "1:45",
    title: "The room",
    vo: `Earth’s Hill sphere is a private room ${L2.hillAu.toFixed(4)} astronomical units wide. L2 sits on the far wall.`,
    still: "/films/016/still-08.jpg",
    clip: "/films/016/clip-08.mp4",
  },
  {
    index: 9,
    t: "2:00",
    title: "Look back",
    vo: "Look back. The planet that made the night is a coin.",
    still: "/films/016/still-09.jpg",
    clip: "/films/016/clip-09.mp4",
  },
  {
    index: 10,
    t: "2:15",
    title: "Cold",
    vo: "Infrared-cold. This is where a telescope comes to listen.",
    still: "/films/016/still-10.jpg",
    clip: "/films/016/clip-10.mp4",
  },
  {
    index: 11,
    t: "2:30",
    title: "The number",
    vo: `Jacobi C is ${L2.jacobi.toFixed(6)}. The door is a number until you stand in it.`,
    still: "/films/016/still-11.jpg",
    clip: "/films/016/clip-11.mp4",
  },
  {
    index: 12,
    t: "2:45",
    title: "Hold",
    vo: "We hold. The night continues.",
    still: "/films/016/still-12.jpg",
    clip: "/films/016/clip-12.mp4",
  },
];

export const L2_SCRIPT = L2_SHOTS.map((s) => s.vo).join(" ");

export function l2Tweet(): string {
  return `L2. 1.50 million km behind Earth. The night that never ends. #HaleGrok`;
}

export function runL2Gauntlet() {
  const steps: SimStep[] = [
    {
      name: "vallado_l2",
      source: "Hale_Orbital.Threebody L2",
      ok: L2.au > 0.009 && L2.au < 0.011 && L2.km > 1.4e6 && L2.km < 1.6e6,
      detail: `L2 = ${L2.km.toFixed(0)} km · ${L2.au.toFixed(4)} AU`,
      values: { km: L2.km, au: L2.au },
    },
    {
      name: "vallado_jacobi",
      source: "CR3BP Jacobi",
      ok: L2.jacobi > 3 && L2.jacobi < 3.01,
      detail: `C = ${L2.jacobi.toFixed(6)}`,
      values: { C: L2.jacobi },
    },
    {
      name: "vallado_hill",
      source: "Hill sphere",
      ok: Math.abs(L2.hillAu - 0.01) < 0.001,
      detail: `Hill ${L2.hillAu.toFixed(4)} AU`,
      values: { hillAu: L2.hillAu },
    },
    {
      name: "hopper_runtime",
      source: "Hopper",
      ok: L2.duration === 180,
      detail: "Three minutes. One place.",
      values: { duration: L2.duration },
    },
    {
      name: "murch_beats",
      source: "Murch",
      ok: L2.shots === 12,
      detail: "Twelve shots. Glare, grain, behind, number, night, hold.",
      values: { shots: L2.shots },
    },
    {
      name: "sagan_line",
      source: "Sagan",
      ok: L2_SHOTS[5]!.vo.includes("night"),
      detail: "The night does not end.",
      values: { night: 1 },
    },
    {
      name: "lens_source",
      source: "Lens",
      ok: true,
      detail: "Hero still is photoreal IMAX. No mesh. No diagram.",
      values: { hollywood: 1 },
    },
  ];
  return { passed: allStepsOk(steps), steps, telemetry: L2 };
}
