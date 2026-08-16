/** Opening reel of The Climb — unique shots, Hale-grounded, no looping beats. */
export type ReelShot = {
  index: number;
  tStart: string;
  file?: string;
  still?: string;
  title: string;
  finding: string;
  prompt: string;
};

export const CLIMB_OPENING: ReelShot[] = [
  {
    index: 1,
    tStart: "0:00",
    file: "/films/001/clip-01.mp4",
    still: "/films/001/still-01.jpg",
    title: "Gloves on the glass",
    finding: "LEO 300 km · v = 7.726 km/s circular",
    prompt:
      "Photoreal IMAX space cinema, 16:9, copper dawn. Tight interior of a transfer-stage cabin at 300 km LEO sunrise. An astronaut's gloved hands rest on a cold porthole; Earth fills the glass, terminator striped copper and bone. No HUD, no numbers, no title card. Physical light only. Quiet, still, 35mm.",
  },
  {
    index: 2,
    tStart: "0:15",
    file: "/films/001/clip-02.mp4",
    still: "/films/001/still-02.jpg",
    title: "First burn",
    finding: "Δv₁ = 2.4257 km/s · Hohmann periapsis",
    prompt:
      "Photoreal IMAX space cinema, 16:9, copper dawn. Side-on exterior, 85mm. A slender transfer stage fires its first Hohmann burn over a curved Earth; a hard copper plume, the stack leaning as the planet slides. No logos, no HUD. Physical light only.",
  },
];
