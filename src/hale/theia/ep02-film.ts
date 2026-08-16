/** Episode 2 — Ten Percent. Routh vs a Mars-mass twin. */
export const EP02 = {
  id: "ep02-ten-percent",
  title: "Ten Percent",
  runtime: "2:00",
  delivery: "4K UHD 3840×2160",
  logline: "Routh holds for dust. A Mars-mass twin is another problem.",
  numbers: {
    muSE: 3.003e-6,
    muTT: 0.0909,
    muRouth: 0.03852,
    theiaMassRatio: 0.1,
  },
};

export type EpShot = {
  index: number;
  tStart: string;
  title: string;
  finding: string;
  still: string;
  file: string;
};

export const EP02_SHOTS: EpShot[] = [
  {
    index: 1,
    tStart: "0:00",
    title: "Dust holds",
    finding: "μ_SE = 3.003×10⁻⁶ ≪ μ* = 0.03852",
    still: "/films/004/still-01.jpg",
    file: "/films/004/clip-01.mp4",
  },
  {
    index: 2,
    tStart: "0:15",
    title: "A seed at L4",
    finding: "Theia is still a test mass. The triangle does not notice.",
    still: "/films/004/still-02.jpg",
    file: "/films/004/clip-02.mp4",
  },
  {
    index: 3,
    tStart: "0:30",
    title: "It eats",
    finding: "Mass grows in the well. Routh is a line you cannot see.",
    still: "/films/004/still-03.jpg",
    file: "/films/004/clip-03.mp4",
  },
  {
    index: 4,
    tStart: "0:45",
    title: "Two rocks",
    finding: "μ = mΘ / (m⊕ + mΘ) is no longer dust",
    still: "/films/004/still-04.jpg",
    file: "/films/004/clip-04.mp4",
  },
  {
    index: 5,
    tStart: "1:00",
    title: "The line",
    finding: "μ* = 0.03852 — Routh’s criterion",
    still: "/films/004/still-05.jpg",
    file: "/films/004/clip-05.mp4",
  },
  {
    index: 6,
    tStart: "1:15",
    title: "Past it",
    finding: "μ_Theia–Terra = 0.0909 > μ*",
    still: "/films/004/still-06.jpg",
    file: "/films/004/clip-06.mp4",
  },
  {
    index: 7,
    tStart: "1:30",
    title: "Ten percent",
    finding: "Theia = 0.1 M⊕ · Belbruno & Gott",
    still: "/films/004/still-07.jpg",
    file: "/films/004/clip-07.mp4",
  },
  {
    index: 8,
    tStart: "1:45",
    title: "The triangle is a lie",
    finding: "It still looks equilateral. The math has already left.",
    still: "/films/004/still-08.jpg",
    file: "/films/004/clip-08.mp4",
  },
];
