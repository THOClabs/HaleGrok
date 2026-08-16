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
  mode: "wander" | "hill" | "hyperbola" | "contact" | "graze" | "energy" | "roche" | "clocks" | "spin" | "luna";
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
  {
    slug: "ep07",
    n: 7,
    title: "Forty-Five Degrees",
    dir: "009",
    master: "/films/009/forty-five-4k.mp4",
    mode: "graze",
    logline: "A grazing geometry. Angular momentum is the reason we have a Moon.",
    shots: shots("009", [
      ["0:00", "The angle", "θ = 45° between r and v"],
      ["0:15", "First touch", "r = 9774 km"],
      ["0:30", "h", "71 063 km²/s"],
      ["0:45", "The miss we keep", "b = 12 777 km"],
      ["1:00", "Not head-on", "Head-on leaves no Moon"],
      ["1:15", "Three cameras", "Theia, Terra, the missing barycenter"],
      ["1:30", "A choice", "Angular momentum is the plot"],
      ["1:45", "Graze", "This is why Luna exists"],
    ]),
  },
  {
    slug: "ep08",
    n: 8,
    title: "Iron Sinks",
    dir: "010",
    master: "/films/010/iron-sinks-4k.mp4",
    mode: "energy",
    logline: "Hale cannot mix mantles. It can count the energy that would try.",
    shots: shots("010", [
      ["0:00", "After", "From far above. No fireball claimed."],
      ["0:15", "Scope", "No mixing. No SPH. No vapor disk."],
      ["0:30", "The number", "v = 10.282 km/s"],
      ["0:45", "KE proxy", "½μv² = 1.915×10⁶"],
      ["1:00", "Iron", "Would sink. Hale will not say it does."],
      ["1:15", "Two worlds", "Still two, in the only picture we are allowed"],
      ["1:30", "Honesty", "Energy only"],
      ["1:45", "Hand-off", "Hydro starts where Hale stops"],
    ]),
  },
  {
    slug: "ep09",
    n: 9,
    title: "Roche",
    dir: "011",
    master: "/films/011/roche-4k.mp4",
    mode: "roche",
    logline: "Inside 2.88 Earth radii you are a ring. Outside you may be Luna.",
    shots: shots("011", [
      ["0:00", "The fence", "Roche fluid 2.88 R⊕"],
      ["0:15", "18 365 km", "Inside this, Luna is a ring"],
      ["0:30", "Rigid", "A lower fence at 1.49 R⊕"],
      ["0:45", "The disk", "Looking inward"],
      ["1:00", "Inner clock", "v_circ = 4.659 km/s"],
      ["1:15", "Outside", "You may be a world"],
      ["1:30", "Today", "60.3 R⊕ — 384 400 km"],
      ["1:45", "The ring that left", "Same gravity, later"],
    ]),
  },
  {
    slug: "ep10",
    n: 10,
    title: "Hours or Years",
    dir: "012",
    master: "/films/012/hours-or-years-4k.mp4",
    mode: "clocks",
    logline: "Hale gives the orbital clock. SPH claims hours. We show both, labeled.",
    shots: shots("012", [
      ["0:00", "Scope", "Orbital clock only"],
      ["0:15", "3 R⊕", "T = 7.32 h"],
      ["0:30", "5 R⊕", "T = 15.74 h"],
      ["0:45", "Roche", "T = 6.88 h"],
      ["1:00", "Hours", "One loop. Not a year."],
      ["1:15", "SPH", "Hours are someone else’s paper"],
      ["1:30", "Labeled", "Hale years ≠ SPH hours"],
      ["1:45", "The inner day", "The disk’s clock"],
    ]),
  },
  {
    slug: "ep11",
    n: 11,
    title: "A Five-Hour Terra",
    dir: "013",
    master: "/films/013/five-hour-terra-4k.mp4",
    mode: "spin",
    logline: "A leftover 5-hour day. Tides took the rest. Hale does not do tides.",
    shots: shots("013", [
      ["0:00", "The leftover", "day* = 5 h"],
      ["0:15", "A mark", "Watch it run"],
      ["0:30", "Today", "day = 24 h"],
      ["0:45", "Tides", "Hale will not compute them"],
      ["1:00", "The month", "Lunar T = 27.28 d"],
      ["1:15", "Far", "60.3 R⊕ already"],
      ["1:30", "Two clocks", "Spin and month, not the same"],
      ["1:45", "What remains", "A world that slowed"],
    ]),
  },
  {
    slug: "ep12",
    n: 12,
    title: "Luna",
    dir: "014",
    master: "/films/014/luna-4k.mp4",
    mode: "luna",
    logline: "The triangle returns, smaller. Earth–Moon L4. 60.3 Earth radii.",
    shots: shots("014", [
      ["0:00", "A new pair", "μ = 0.01215"],
      ["0:15", "L1", "x = 0.8369"],
      ["0:30", "The saddle", "A new door"],
      ["0:45", "L4", "The triangle returns"],
      ["1:00", "Stable", "Routh holds for dust again"],
      ["1:15", "60.3 R⊕", "How far, again"],
      ["1:30", "Same geometry", "Smaller sky"],
      ["1:45", "Home", "The problem we still have"],
    ]),
  },
];

export function filmBySlug(slug: string): FilmDef | undefined {
  return SERIES_FILMS.find((f) => f.slug === slug);
}
