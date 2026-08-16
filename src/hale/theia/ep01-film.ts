/** Episode 1 — The Trojan Twin. Eight unique shots from the L4 gauntlet. */
export const EP01 = {
  id: "ep01-trojan-twin",
  title: "The Trojan Twin",
  runtime: "2:00",
  delivery: "4K UHD 3840×2160",
  logline: "Theia sits at Sun–Terra L4. Same year. Sixty degrees of black.",
  numbers: {
    x: 0.499997,
    y: 0.866025,
    angleDeg: 60.0,
    periodDays: 365.26,
    jacobi: 2.999997,
    accMag: 3.74e-17,
  },
};

export type Ep01Shot = {
  index: number;
  tStart: string;
  title: string;
  finding: string;
  still: string;
  file: string;
  prompt: string;
};

export const EP01_SHOTS: Ep01Shot[] = [
  {
    index: 1,
    tStart: "0:00",
    title: "The triangle from above",
    finding: "L4 x=0.499997 y=0.866025",
    still: "/films/003/still-01.jpg",
    file: "/films/003/clip-01.mp4",
    prompt:
      "Science documentary IMAX, 16:9, no people, no text, no HUD. Looking straight down on the early solar ecliptic. The Sun is a fierce small disk. Terra is a living blue-white world on a thin implied circle. Sixty degrees ahead, at L4, a darker Mars-sized body — Theia — incomplete, rust and ash. The three form a perfect equilateral. Vast black. Physical sunlight only.",
  },
  {
    index: 2,
    tStart: "0:15",
    title: "A world, not a spark",
    finding: "Theia ≈ 0.1 M⊕ at 1 AU",
    still: "/films/003/still-02.jpg",
    file: "/films/003/clip-02.mp4",
    prompt:
      "Science documentary IMAX, 16:9, no people, no text. Close on Theia: a Mars-sized protoplanet, unfinished, rust, basalt, thin haze, 1 AU from a hard white Sun. No Moon in its sky. Photoreal, quiet, Hadean. Not Earth. Not Mars as we know it — a twin that will not last.",
  },
  {
    index: 3,
    tStart: "0:30",
    title: "Looking home at 60°",
    finding: "angle 60.00°",
    still: "/films/003/still-03.jpg",
    file: "/films/003/clip-03.mp4",
    prompt:
      "Science documentary IMAX, 16:9, no people, no text. From just above Theia’s terminator, looking back along the shared orbit. Terra is a small blue point sixty degrees behind on the same circle. The Sun off-frame left. The black between them is the subject. Photoreal.",
  },
  {
    index: 4,
    tStart: "0:45",
    title: "Sixty degrees of black",
    finding: "year 365.26 d",
    still: "/films/003/still-04.jpg",
    file: "/films/003/clip-04.mp4",
    prompt:
      "Science documentary IMAX, 16:9, no people, no text. Empty space on the 1 AU circle between Terra and Theia. Neither world fills the frame. A faint zodiacal dust hint only. The Sun a distant glare. The year they share is invisible. Photoreal emptiness.",
  },
  {
    index: 5,
    tStart: "1:00",
    title: "The year they share",
    finding: "T = 365.26 d",
    still: "/films/003/still-05.jpg",
    file: "/films/003/clip-05.mp4",
    prompt:
      "Science documentary IMAX, 16:9, no people, no text. High above the Sun. One thin pale orbital path. Two worlds on it, sixty degrees apart — Terra blue, Theia rust. They will complete the same year. Slow, precise, photoreal. No diagram lines brighter than dust.",
  },
  {
    index: 6,
    tStart: "1:15",
    title: "The same Sun",
    finding: "r = 1 AU for both",
    still: "/films/003/still-06.jpg",
    file: "/films/003/clip-06.mp4",
    prompt:
      "Science documentary IMAX, 16:9, no people, no text. Theia’s day side. The Sun is the same angular size it is from Terra. A Hadean rust landscape, no life, no Moon. Hard shadows. Photoreal. Quiet.",
  },
  {
    index: 7,
    tStart: "1:30",
    title: "Force is zero",
    finding: "|a| = 3.7e-17 in the rotating frame",
    still: "/films/003/still-07.jpg",
    file: "/films/003/clip-07.mp4",
    prompt:
      "Science documentary IMAX, 16:9, no people, no text. Theia hanging motionless relative to Terra and the Sun, as if the three were nailed to a slowly turning plate. A sense of eerie stillness in a moving sky of distant stars. Photoreal. No HUD.",
  },
  {
    index: 8,
    tStart: "1:45",
    title: "C = 2.999997",
    finding: "Jacobi constant at L4",
    still: "/films/003/still-08.jpg",
    file: "/films/003/clip-08.mp4",
    prompt:
      "Science documentary IMAX, 16:9, no people, no text. Final hold: Sun, Terra, Theia in the equilateral, slightly further back than the opening. The triangle looks inevitable and temporary. Photoreal, cold, no text, no ships.",
  },
];
