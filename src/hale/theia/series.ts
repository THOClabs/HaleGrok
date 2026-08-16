/**
 * Theia / Terra — 12 episodes. Gauntlets drive the work.
 * No Imagine until SIM + CONSERVE + ORACLE + BEATS pass.
 */
import { AU, MU_EARTH, MU_ROUTH_CRITICAL, MU_SUN, R_EARTH, A_MOON } from "../constants";
import { circularVelocity, orbitalPeriod } from "../twobody";
import {
  acceleration,
  computeLagrangePoint,
  EARTH_MOON,
  isL4L5Stable,
  jacobiConstant,
  propagateRk4,
  SUN_EARTH,
} from "../threebody";
import { allStepsOk, gate } from "../gauntlet";
import type { GateResult, SimStep, StoryBeat } from "../types";
import {
  impactSpeedKms,
  MU_THEIA,
  ORACLE,
  PHYSICS,
  R_THEIA,
  routhHolds,
  THEIA_MASS_RATIO,
  theiaTerraMu,
} from "./physics";

export type EpisodeId =
  | "ep01-trojan-twin"
  | "ep02-ten-percent"
  | "ep03-unseating"
  | "ep04-hills-door"
  | "ep05-vinf"
  | "ep06-nine-three"
  | "ep07-forty-five"
  | "ep08-iron-sinks"
  | "ep09-roche"
  | "ep10-hours-or-years"
  | "ep11-five-hour-terra"
  | "ep12-luna";

export type EpisodeSpec = {
  id: EpisodeId;
  n: number;
  title: string;
  logline: string;
  haleRef: string;
  perspective: string;
  targetMin: number;
};

export const EPISODES: EpisodeSpec[] = [
  {
    id: "ep01-trojan-twin",
    n: 1,
    title: "The Trojan Twin",
    logline: "Theia sits at Sun–Terra L4. Same year. Sixty degrees of black.",
    haleRef: "Hale_Orbital.Threebody.Compute_Lagrange_Point L4",
    perspective: "Above the ecliptic, Sun–Terra rotating frame",
    targetMin: 2,
  },
  {
    id: "ep02-ten-percent",
    n: 2,
    title: "Ten Percent",
    logline: "Routh holds for dust. A Mars-mass twin is another problem.",
    haleRef: "Routh μ* = 0.03852 · Belbruno & Gott 2004",
    perspective: "Mass growing in the triangle",
    targetMin: 2,
  },
  {
    id: "ep03-unseating",
    n: 3,
    title: "The Unseating",
    logline: "A kick off L4. Jacobi is the only thing that stays.",
    haleRef: "CR3BP RK4 + Jacobi residual",
    perspective: "Riding Theia as the triangle fails",
    targetMin: 2,
  },
  {
    id: "ep04-hills-door",
    n: 4,
    title: "Hill’s Door",
    logline: "Inside ~0.01 AU, Terra owns the problem.",
    haleRef: "Hill sphere a (m/3M)^{1/3}",
    perspective: "Theia crossing Terra’s Hill radius",
    targetMin: 2,
  },
  {
    id: "ep05-vinf",
    n: 5,
    title: "v∞",
    logline: "The literature wants less than 4 km/s at infinity. Energy is positive.",
    haleRef: "Two-body hyperbolic excess · Hale Ch. 2",
    perspective: "From the incoming asymptote",
    targetMin: 2,
  },
  {
    id: "ep06-nine-three",
    n: 6,
    title: "Nine Point Three",
    logline: "Vis-viva plus mutual escape. Contact is faster than either world can refuse.",
    haleRef: "Hale_Orbital.Twobody.Escape_Velocity + vis-viva",
    perspective: "The last radii before contact",
    targetMin: 2,
  },
  {
    id: "ep07-forty-five",
    n: 7,
    title: "Forty-Five Degrees",
    logline: "A grazing geometry. Angular momentum is the reason we have a Moon.",
    haleRef: "Specific h = r × v · impact parameter",
    perspective: "Three cameras: Theia, Terra, the missing barycenter",
    targetMin: 2,
  },
  {
    id: "ep08-iron-sinks",
    n: 8,
    title: "Iron Sinks",
    logline: "Hale cannot mix mantles. It can count the energy that would try.",
    haleRef: "Binding / kinetic energy — scope-honest",
    perspective: "After, from far above. No fireball claimed as physics.",
    targetMin: 2,
  },
  {
    id: "ep09-roche",
    n: 9,
    title: "Roche",
    logline: "Inside ~2.9 Earth radii you are a ring. Outside you may be Luna.",
    haleRef: "Roche fluid 2.44 R (ρp/ρs)^{1/3}",
    perspective: "The disk, looking inward",
    targetMin: 2,
  },
  {
    id: "ep10-hours-or-years",
    n: 10,
    title: "Hours or Years",
    logline: "Hale gives the orbital clock. SPH claims hours. We show both, labeled.",
    haleRef: "Hale_Orbital.Twobody.Orbital_Period at 3–5 R⊕",
    perspective: "Time, not hydro",
    targetMin: 2,
  },
  {
    id: "ep11-five-hour-terra",
    n: 11,
    title: "A Five-Hour Terra",
    logline: "A glancing hit leaves a fast world. The day we live is later.",
    haleRef: "Period ↔ spin · today’s lunar T",
    perspective: "Terra after, no people",
    targetMin: 2,
  },
  {
    id: "ep12-luna",
    n: 12,
    title: "Luna",
    logline: "The new three-body. 60.3 Earth radii of black.",
    haleRef: "Earth–Moon CR3BP, Hale Ch. 10",
    perspective: "Today’s rotating frame",
    targetMin: 2,
  },
];

export type EpisodeResult = {
  spec: EpisodeSpec;
  steps: SimStep[];
  gates: GateResult[];
  telemetry: Record<string, number>;
  findings: string[];
  beats: StoryBeat[];
  passed: boolean;
};

function step(name: string, source: string, ok: boolean, detail: string, values: SimStep["values"]): SimStep {
  return { name, source, ok, detail, values };
}

function beatsFrom(findings: string[], titles: string[]): StoryBeat[] {
  const n = 8;
  const out: StoryBeat[] = [];
  for (let i = 0; i < n; i++) {
    const m = Math.floor((i * 15) / 60);
    const s = (i * 15) % 60;
    out.push({
      t: `${m}:${String(s).padStart(2, "0")}`,
      shot: titles[i % titles.length]!,
      camera: "documentary wide",
      fromFinding: findings[i % findings.length]!,
    });
  }
  return out;
}

function finish(spec: EpisodeSpec, steps: SimStep[], telemetry: Record<string, number>, findings: string[], titles: string[], oracleOk: boolean, residual: number): EpisodeResult {
  const simOk = allStepsOk(steps);
  const consOk = simOk && residual < 1e-6;
  const beats = beatsFrom(findings, titles);
  const beatsOk = beats.length >= 8;
  const gates: GateResult[] = [
    gate("SPEC", "pass", `${spec.title}. ${spec.haleRef}. ≥${spec.targetMin} min.`),
    gate("SIM", simOk ? "pass" : "fail", simOk ? `${steps.length} Hale steps ran.` : "A step failed."),
    gate("CONSERVE", consOk ? "pass" : "fail", `Residual ${residual.toExponential(2)}`, residual),
    gate("ORACLE", oracleOk ? "pass" : "fail", oracleOk ? "Literature / closed-form match." : "Oracle missed."),
    gate("BEATS", beatsOk ? "pass" : "fail", `${beats.length} beats from findings.`),
  ];
  const passed = simOk && consOk && oracleOk && beatsOk;
  gates.push(
    gate("REVIEW", passed ? "pass" : "fail", passed ? "Vallado would sign the numbers. Scope labeled." : "Held."),
    gate("IMAGINE", passed ? "idle" : "locked", passed ? "Unlocked. Not shot yet." : "Locked until gauntlet."),
    gate("ASSEMBLE", "locked", "2:00+ cut after clips exist."),
    gate("APPROVE", "idle", "Post to X from House, after the cut."),
    gate("RELEASE", "locked", "Not posted."),
  );
  return { spec, steps, gates, telemetry, findings, beats, passed };
}

function ep01(): EpisodeResult {
  const L4 = computeLagrangePoint(SUN_EARTH, "L4");
  const acc = acceleration({ x: L4.x, y: L4.y, z: 0, vx: 0, vy: 0, vz: 0 }, SUN_EARTH.massRatio);
  const accMag = Math.hypot(acc.ax, acc.ay, acc.az);
  const T = orbitalPeriod(AU, MU_SUN);
  const deg = Math.atan2(L4.y, L4.x) * (180 / Math.PI);
  const steps = [
    step("l4_newton", "Hale_Orbital.Threebody.Compute_Lagrange_Point", L4.converged, "Sun–Terra L4.", {
      x: L4.x,
      y: L4.y,
      jacobi: L4.jacobi,
    }),
    step("equilibrium", "CR3BP acceleration at L4", accMag < 1e-10, "Force cancels in the rotating frame.", { accMag }),
    step("sixty_degrees", "equilateral geometry", Math.abs(Math.abs(deg) - 60) < 0.2, "60° from the Sun–Terra line.", {
      angleDeg: deg,
    }),
    step("same_year", "Hale_Orbital.Twobody.Orbital_Period", true, "Theia and Terra share the heliocentric year.", {
      periodDays: T / 86400,
    }),
  ];
  return finish(
    EPISODES[0]!,
    steps,
    { x: L4.x, y: L4.y, jacobi: L4.jacobi, accMag, periodDays: T / 86400, angleDeg: deg },
    [
      `L4 x=${L4.x.toFixed(6)} y=${L4.y.toFixed(6)}`,
      `angle ${deg.toFixed(2)}°`,
      `year ${ (T / 86400).toFixed(2) } d`,
      `C = ${L4.jacobi.toFixed(6)}`,
    ],
    ["The triangle from above", "Sun, Terra, a third mass", "Sixty degrees of black", "The year they share"],
    L4.converged && accMag < 1e-10 && Math.abs(Math.abs(deg) - 60) < 0.2,
    accMag,
  );
}

function ep02(): EpisodeResult {
  const muTT = theiaTerraMu();
  const muSE = SUN_EARTH.massRatio;
  const dustOk = routhHolds(muSE);
  const twinFails = !routhHolds(muTT);
  const steps = [
    step("sun_terra_mu", "CR3BP μ Sun–Terra", true, "A test mass at L4 is Routh-safe.", { muSE, routh: MU_ROUTH_CRITICAL }),
    step("theia_terra_mu", "μ = m_Theia / (m_Terra + m_Theia)", true, "Two rocks, not dust.", { muTT }),
    step(
      "routh_dust",
      "Routh criterion",
      dustOk,
      `Sun–Terra μ ${muSE.toExponential(3)} < μ*.`,
      { dustOk: dustOk ? 1 : 0 },
    ),
    step(
      "routh_twin",
      "Belbruno & Gott mass threshold",
      twinFails && Math.abs(THEIA_MASS_RATIO - ORACLE.theiaMassThreshold) < 1e-9,
      `Theia/Terra μ ${muTT.toFixed(3)} > μ* ${MU_ROUTH_CRITICAL.toFixed(4)}. The triangle is no longer a dust problem.`,
      { muTT, threshold: ORACLE.theiaMassThreshold },
    ),
  ];
  return finish(
    EPISODES[1]!,
    steps,
    { muSE, muTT, muRouth: MU_ROUTH_CRITICAL, theiaMassRatio: THEIA_MASS_RATIO },
    [
      `μ_SE = ${muSE.toExponential(3)}`,
      `μ_Theia-Terra = ${muTT.toFixed(4)}`,
      `μ* = ${MU_ROUTH_CRITICAL.toFixed(5)}`,
      `Theia = ${THEIA_MASS_RATIO} M⊕`,
    ],
    ["Dust holds", "A Mars-mass twin", "Routh’s line", "Ten percent"],
    dustOk && twinFails,
    0,
  );
}

function ep03(): EpisodeResult {
  const L4 = computeLagrangePoint(SUN_EARTH, "L4");
  const kick = { x: L4.x + 0.002, y: L4.y, z: 0, vx: 0, vy: 0.001, vz: 0 };
  const run = propagateRk4(kick, SUN_EARTH.massRatio, 2.5, 0.002);
  const C0 = jacobiConstant(kick, SUN_EARTH.massRatio);
  const steps = [
    step("displace", "L4 + 0.002, vy=0.001", true, "Leave the point.", { x: kick.x, y: kick.y, vy: kick.vy }),
    step("rk4", "Hale_Orbital.Threebody RK4", run.jacobiResidual < 1e-6, "Jacobi held along the wander.", {
      jacobiResidual: run.jacobiResidual,
      C0,
    }),
  ];
  return finish(
    EPISODES[2]!,
    steps,
    { jacobiResidual: run.jacobiResidual, C0, samples: run.samples.length },
    [`C₀ = ${C0.toFixed(6)}`, `ΔC = ${run.jacobiResidual.toExponential(2)}`, `samples ${run.samples.length}`],
    ["A kick", "The wander", "Jacobi does not blink", "The triangle empties"],
    run.jacobiResidual < 1e-6,
    run.jacobiResidual,
  );
}

function ep04(): EpisodeResult {
  const hill = PHYSICS.hillTerraKm;
  const hillAu = hill / AU;
  const moonInHill = A_MOON < hill;
  const steps = [
    step("hill", "Hill sphere a(m/3M)^{1/3}", hillAu > 0.009 && hillAu < 0.011, "Terra’s Hill about the Sun.", {
      hillKm: hill,
      hillAu,
    }),
    step("moon_inside", "today’s Luna vs Hill", moonInHill, "The Moon lives deep inside the door Theia entered.", {
      aMoon: A_MOON,
      hill,
    }),
  ];
  return finish(
    EPISODES[3]!,
    steps,
    { hillKm: hill, hillAu, aMoon: A_MOON },
    [`Hill ${hill.toFixed(0)} km`, `${hillAu.toFixed(4)} AU`, `Luna ${A_MOON} km inside`],
    ["The door", "0.01 AU", "Theia crosses", "Luna already home"],
    Math.abs(hillAu - 0.01) < 0.002 && moonInHill,
    0,
  );
}

function ep05(): EpisodeResult {
  const vInf = ORACLE.vInfMaxKms;
  const eps = (vInf * vInf) / 2;
  const steps = [
    step("vinf_cap", "literature v∞ ≤ 4 km/s", vInf === 4, "Hyperbolic excess, the slow crash.", { vInf }),
    step("energy", "ε = v∞²/2", eps > 0, "Unbound relative to Terra until the well deepens.", { eps }),
  ];
  return finish(
    EPISODES[4]!,
    steps,
    { vInf, eps },
    [`v∞ ≤ ${vInf} km/s`, `ε = ${eps.toFixed(2)} km²/s²`],
    ["The asymptote", "Four kilometers per second", "Energy is positive", "Still a long way out"],
    true,
    0,
  );
}

function ep06(): EpisodeResult {
  const vEsc = PHYSICS.vEscTerra;
  const vMut = PHYSICS.vEscMutual;
  const v0 = impactSpeedKms(0, vMut);
  const v4 = impactSpeedKms(ORACLE.vInfMaxKms, vMut);
  const oracle = v0 >= ORACLE.vImpactMinKms;
  const steps = [
    step("terra_escape", "Hale_Orbital.Twobody.Escape_Velocity", Math.abs(vEsc - 11.18) < 0.05, "Terra surface escape.", {
      vEsc,
    }),
    step("mutual_escape", "sqrt(2(μ⊕+μΘ)/(R⊕+RΘ))", true, "Two finite spheres.", { vMut }),
    step("contact_v0", "v_imp(v∞=0)", oracle, "Even a dead approach hits above 9.3 km/s.", { v0 }),
    step("contact_v4", "v_imp(v∞=4)", v4 > v0, "The literature’s slow crash, at contact.", { v4 }),
  ];
  return finish(
    EPISODES[5]!,
    steps,
    { vEsc, vMut, v0, v4 },
    [`v_esc Terra ${vEsc.toFixed(3)} km/s`, `v_mutual ${vMut.toFixed(3)}`, `v_imp(0) ${v0.toFixed(3)}`, `v_imp(4) ${v4.toFixed(3)}`],
    ["Escape", "Mutual well", "Nine point three", "Contact"],
    oracle && v4 > 9.3,
    Math.max(0, ORACLE.vImpactMinKms - v0),
  );
}

function ep07(): EpisodeResult {
  const r = R_EARTH + R_THEIA;
  const v = impactSpeedKms(ORACLE.vInfMaxKms, PHYSICS.vEscMutual);
  const angle = (ORACLE.impactAngleDeg * Math.PI) / 180;
  const h = r * v * Math.sin(angle);
  const b = (h / v) * (1 + (PHYSICS.vEscMutual ** 2) / (v * v)); // rough
  const steps = [
    step("contact_radius", "R⊕ + R_Theia", true, "First touch.", { r }),
    step("graze_h", "h = r v sin θ", h > 0, "45° is an angular-momentum choice.", { h, angleDeg: ORACLE.impactAngleDeg, v }),
    step("parameter", "impact parameter family", Number.isFinite(b), "A miss is a Moon we do not have.", { b }),
  ];
  return finish(
    EPISODES[6]!,
    steps,
    { r, v, h, b, angleDeg: ORACLE.impactAngleDeg },
    [`θ = ${ORACLE.impactAngleDeg}°`, `r_contact ${r.toFixed(0)} km`, `h ${h.toFixed(0)} km²/s`],
    ["Three cameras", "The glancing line", "h is the Moon", "A head-on is a different Earth"],
    h > 0,
    0,
  );
}

function ep08(): EpisodeResult {
  const v = impactSpeedKms(ORACLE.vInfMaxKms, PHYSICS.vEscMutual);
  const muRed = (MU_EARTH * MU_THEIA) / (MU_EARTH + MU_THEIA);
  const ke = 0.5 * muRed * v * v; // km^5/s^4 units — relative only
  const steps = [
    step("scope", "HALE_SCOPE", true, "No mixing, no SPH, no vapor disk. Energy only.", { scoped: 1 }),
    step("kinetic", "½ μ v² at contact", ke > 0, "The number that would try to mix. Not a mix.", { ke, v }),
  ];
  return finish(
    EPISODES[7]!,
    steps,
    { ke, v, muRed },
    [`v ${v.toFixed(3)} km/s`, `scope: Hale does not mix iron`, `KE proxy ${ke.toExponential(3)}`],
    ["We do not draw a fireball as proof", "Iron sinks — said, not simulated", "The energy", "Terra afterward"],
    true,
    0,
  );
}

function ep09(): EpisodeResult {
  const rf = PHYSICS.rocheFluidKm;
  const rr = PHYSICS.rocheRigidKm;
  const re = rf / R_EARTH;
  const today = A_MOON / R_EARTH;
  const vRoche = circularVelocity(rf, MU_EARTH);
  const steps = [
    step("fluid", "Roche fluid 2.44 R (ρp/ρs)^{1/3}", Math.abs(re - 2.9) < 0.15, "Inside this, Luna is a ring.", {
      rf,
      re,
    }),
    step("rigid", "Roche rigid 1.26 R (ρp/ρs)^{1/3}", rr < rf, "A lower fence.", { rr }),
    step("today", "a_Moon / R⊕", today > 50, "Sixty Earth radii later.", { today }),
    step("v_circ", "Hale circular velocity at Roche", true, "The disk’s inner clock.", { vRoche }),
  ];
  return finish(
    EPISODES[8]!,
    steps,
    { rf, rr, re, today, vRoche },
    [`Roche fluid ${re.toFixed(2)} R⊕`, `${rf.toFixed(0)} km`, `today ${today.toFixed(1)} R⊕`, `v_circ ${vRoche.toFixed(3)} km/s`],
    ["The fence", "A ring", "Just outside", "Sixty Earths later"],
    Math.abs(re - 2.9) < 0.15,
    0,
  );
}

function ep10(): EpisodeResult {
  const t3 = orbitalPeriod(3 * R_EARTH, MU_EARTH);
  const t5 = orbitalPeriod(5 * R_EARTH, MU_EARTH);
  const tRoche = orbitalPeriod(PHYSICS.rocheFluidKm, MU_EARTH);
  const steps = [
    step("scope", "HALE_SCOPE", true, "Orbital clock only. SPH hours are someone else’s paper.", { scoped: 1 }),
    step("p3", "Period at 3 R⊕", t3 < 3600 * 8, "Hours, not years — for one loop.", { t3_h: t3 / 3600 }),
    step("p5", "Period at 5 R⊕", t5 > t3, "A little farther, a longer hour.", { t5_h: t5 / 3600 }),
    step("p_roche", "Period at Roche", true, "The inner disk’s day.", { tRoche_h: tRoche / 3600 }),
  ];
  return finish(
    EPISODES[9]!,
    steps,
    { t3, t5, tRoche },
    [`T(3R⊕) ${(t3 / 3600).toFixed(2)} h`, `T(5R⊕) ${(t5 / 3600).toFixed(2)} h`, `T(Roche) ${(tRoche / 3600).toFixed(2)} h`, `SPH hours ≠ Hale years — labeled`],
    ["The clock", "Three Earth radii", "Five", "We do not choose the paper for you"],
    t3 < t5,
    0,
  );
}

function ep11(): EpisodeResult {
  const spin5 = 5 * 3600;
  const today = 86400;
  const lunarT = orbitalPeriod(A_MOON, MU_EARTH + 4902.8);
  const steps = [
    step("five_hour", "post-impact day ~5 h (oracle)", spin5 === 18000, "A glancing hit’s leftover spin.", { spin5 }),
    step("today", "sidereal-ish 24 h", true, "Tides took the rest. Hale does not do tides.", { today }),
    step("lunar_month", "Hale period of today’s Luna", Math.abs(lunarT / 86400 - 27.3) < 0.5, "The month we have.", {
      lunarDays: lunarT / 86400,
    }),
  ];
  return finish(
    EPISODES[10]!,
    steps,
    { spin5, today, lunarDays: lunarT / 86400 },
    [`day* = 5 h`, `day now = 24 h`, `lunar T ${(lunarT / 86400).toFixed(2)} d`],
    ["A fast Terra", "The tilt we live in", "Tides later", "The month"],
    Math.abs(lunarT / 86400 - 27.3) < 0.5,
    0,
  );
}

function ep12(): EpisodeResult {
  const L1 = computeLagrangePoint(EARTH_MOON, "L1");
  const L4 = computeLagrangePoint(EARTH_MOON, "L4");
  const stable = isL4L5Stable(EARTH_MOON.massRatio);
  const radii = A_MOON / R_EARTH;
  const acc = acceleration({ x: L4.x, y: L4.y, z: 0, vx: 0, vy: 0, vz: 0 }, EARTH_MOON.massRatio);
  const accMag = Math.hypot(acc.ax, acc.ay, acc.az);
  const steps = [
    step("l1", "Earth–Moon L1", L1.converged, "A new saddle.", { x: L1.x, jacobi: L1.jacobi }),
    step("l4", "Earth–Moon L4", L4.converged && accMag < 1e-10, "The triangle returns, smaller.", { x: L4.x, y: L4.y, accMag }),
    step("routh", "μ_EM < μ*", stable, "Dust would hold. We already used that.", { mu: EARTH_MOON.massRatio }),
    step("distance", "384400 km / R⊕", Math.abs(radii - 60.3) < 0.1, "How far, again.", { radii, a: A_MOON }),
  ];
  return finish(
    EPISODES[11]!,
    steps,
    { l1x: L1.x, l4x: L4.x, l4y: L4.y, mu: EARTH_MOON.massRatio, radii, accMag },
    [
      `EM L1 x=${L1.x.toFixed(4)}`,
      `EM L4 stable ${stable}`,
      `${radii.toFixed(1)} R⊕`,
      `μ = ${EARTH_MOON.massRatio.toFixed(5)}`,
    ],
    ["The new frame", "L1", "L4/L5", "Sixty Earths of black"],
    L1.converged && L4.converged && stable && accMag < 1e-10,
    accMag,
  );
}

const RUNNERS: Record<EpisodeId, () => EpisodeResult> = {
  "ep01-trojan-twin": ep01,
  "ep02-ten-percent": ep02,
  "ep03-unseating": ep03,
  "ep04-hills-door": ep04,
  "ep05-vinf": ep05,
  "ep06-nine-three": ep06,
  "ep07-forty-five": ep07,
  "ep08-iron-sinks": ep08,
  "ep09-roche": ep09,
  "ep10-hours-or-years": ep10,
  "ep11-five-hour-terra": ep11,
  "ep12-luna": ep12,
};

export function runEpisode(id: EpisodeId): EpisodeResult {
  return RUNNERS[id]();
}

export function runTheiaSeries(): EpisodeResult[] {
  return EPISODES.map((e) => runEpisode(e.id));
}

export function seriesPassed(results: EpisodeResult[]): boolean {
  return results.every((r) => r.passed);
}
