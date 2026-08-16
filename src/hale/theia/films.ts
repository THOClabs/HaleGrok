export type FilmShot = {
  index: number;
  tStart: string;
  title: string;
  finding: string;
  still: string;
  file: string;
};

export type FilmDef = {
  slug: string;
  n: number;
  title: string;
  dir: string;
  master: string;
  mode: "wander" | "hill" | "hyperbola" | "contact";
  logline: string;
  shots: FilmShot[];
};

function shots(dir: string, rows: Array<[string, string, string]>): FilmShot[] {
  return rows.map((row, i) => {
    const n = String(i + 1).padStart(2, "0");
    return {
      index: i + 1,
      tStart: row[0]!,
      title: row[1]!,
      finding: row[2]!,
      still: `/films/${dir}/still-${n}.jpg`,
      file: `/films/${dir}/clip-${n}.mp4`,
    };
  });
}

export const SERIES_FILMS: FilmDef[] = [
  {
    slug: "ep03",
    n: 3,
    title: "The Unseating",
    dir: "005",
    master: "/films/005/the-unseating-4k.mp4",
    mode: "wander",
    logline: "A kick off L4. Jacobi is the only thing that stays.",
    shots: shots("005", [
      ["0:00", "The kick", "L4 + 0.002, vy = 0.001"],
      ["0:15", "Off the point", "The triangle does not hold a world"],
      ["0:30", "RK4", "480 samples. Hale’s integrator."],
      ["0:45", "The trail", "A wander, not a fall — yet"],
      ["1:00", "Jacobi", "C₀ = 2.999999 · ΔC = 0"],
      ["1:15", "Terra still sits", "The year continues without Theia"],
      ["1:30", "L4 empty", "A point again. Not a home."],
      ["1:45", "Held", "The constant did not blink"],
    ]),
  },
  {
    slug: "ep04",
    n: 4,
    title: "Hill’s Door",
    dir: "006",
    master: "/films/006/hills-door-4k.mp4",
    mode: "hill",
    logline: "Inside 0.0100 AU, Terra owns the problem.",
    shots: shots("006", [
      ["0:00", "Pull back", "The year is still the Sun’s"],
      ["0:15", "A private room", "Hill sphere of Terra"],
      ["0:30", "0.0100 AU", "1 496 555 km"],
      ["0:45", "Theia outside", "Still the Sun’s passenger"],
      ["1:00", "The door", "a (m/3M)¹ᐟ³"],
      ["1:15", "Crossing", "The problem changes owner"],
      ["1:30", "Luna already home", "384 400 km inside the same door"],
      ["1:45", "Inside", "From here the Sun is a perturbation"],
    ]),
  },
  {
    slug: "ep05",
    n: 5,
    title: "v∞",
    dir: "007",
    master: "/films/007/vinf-4k.mp4",
    mode: "hyperbola",
    logline: "Less than 4 km/s at infinity. Energy is positive.",
    shots: shots("007", [
      ["0:00", "The asymptote", "A straight line that will not stay straight"],
      ["0:15", "Four kilometers", "v∞ ≤ 4 km/s"],
      ["0:30", "ε = 8", "v∞²/2 · unbound"],
      ["0:45", "Far", "Terra is a grain"],
      ["1:00", "The bend begins", "Gravity is slow at first"],
      ["1:15", "Still outgoing in spirit", "Hyperbola, not ellipse"],
      ["1:30", "The well", "ε stays positive"],
      ["1:45", "Inbound", "A slow crash, astronomically"],
    ]),
  },
  {
    slug: "ep06",
    n: 6,
    title: "Nine Point Three",
    dir: "008",
    master: "/films/008/nine-point-three-4k.mp4",
    mode: "contact",
    logline: "Even a dead approach hits above 9.3 km/s.",
    shots: shots("008", [
      ["0:00", "Terra’s escape", "11.180 km/s at the surface"],
      ["0:15", "Two spheres", "R⊕ + R_Theia = 9774 km"],
      ["0:30", "Mutual well", "v_esc,mutual = 9.472 km/s"],
      ["0:45", "Dead approach", "v∞ = 0 still kills"],
      ["1:00", "Add four", "v_imp(4) = 10.282 km/s"],
      ["1:15", "Literature", "≳ 9.3 km/s at contact"],
      ["1:30", "Last radii", "Vis-viva has already spoken"],
      ["1:45", "Contact", "Hale stops. Hydro begins."],
    ]),
  },
];

export function filmBySlug(slug: string): FilmDef | undefined {
  return SERIES_FILMS.find((f) => f.slug === slug);
}
