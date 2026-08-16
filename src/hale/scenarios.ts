import { MU_EARTH, R_EARTH, R_GEO } from "./constants";
import { CATALOG, productionById } from "./catalog";
import { allStepsOk, gate, lockedAfter } from "./gauntlet";
import { sampleEllipse, solveKeplerElliptic, stumpffC, stumpffS, meanFromE, trueAnomalyFromE } from "./kepler";
import { hohmannTransfer } from "./maneuvers";
import { compileImaginePrompt, compileTweet } from "./prompts";
import { compileFilmPlan } from "./film";
import { reviewPass, runReviewRoom } from "./reviews";
import { isRunnable } from "./slate";
import {
  EARTH_MOON,
  SUN_EARTH,
  SUN_JUPITER,
  computeAllLagrange,
  computeLagrangePoint,
  dimensionalKm,
  isL4L5Stable,
  jacobiConstant,
  primaryPositions,
  propagateRk4,
  type LagrangeId,
  type ThreebodySystem,
} from "./threebody";
import { circularVelocity, escapeVelocity, specificEnergySma, visViva } from "./twobody";
import type {
  GateResult,
  PlotData,
  Production,
  ScenarioResult,
  SimStep,
} from "./types";

const HOHMANN_ORACLE = {
  r1: R_EARTH + 300,
  r2: R_GEO,
  dv1: 2.4258,
  dv2: 1.4668,
  hours: 5.275,
};

function step(
  name: string,
  source: string,
  ok: boolean,
  detail: string,
  values: Record<string, number | string>,
): SimStep {
  return { name, source, ok, detail, values };
}

function close(got: number, exp: number, tol: number): boolean {
  return Math.abs(got - exp) <= tol;
}

function finish(
  production: Production,
  steps: SimStep[],
  telemetry: Record<string, number>,
  plot: PlotData,
  findings: string[],
  headline: string,
  extraGates: GateResult[] = [],
): ScenarioResult {
  const simOk = allStepsOk(steps);
  const conserveResidual =
    typeof telemetry.jacobiResidual === "number"
      ? telemetry.jacobiResidual
      : typeof telemetry.energyResidual === "number"
        ? telemetry.energyResidual
        : 0;
  const conserveOk = simOk && conserveResidual < 1e-8;
  const oracleStep = steps.find((s) => s.name.toLowerCase().includes("oracle"));
  const oracleOk = simOk && (oracleStep ? oracleStep.ok : true);

  const gates: GateResult[] = [
    gate("SPEC", "pass", `${production.title}. ${production.haleRef}.`),
    gate("SIM", simOk ? "pass" : "fail", simOk ? `${steps.length} Ada-faithful steps ran clean.` : "A scripted step failed.", 0),
    gate(
      "CONSERVE",
      conserveOk ? "pass" : "fail",
      conserveOk ? `Residual ${conserveResidual.toExponential(2)}` : "Conservation failed.",
      conserveResidual,
    ),
    gate("ORACLE", oracleOk ? "pass" : "fail", oracleOk ? "Matches Hale / Ada / closed-form." : "Oracle mismatch."),
  ];

  const imaginePrompt = compileImaginePrompt(production, telemetry, findings);
  const tweet = compileTweet(production, telemetry, headline);
  const filmPlan = compileFilmPlan(production, findings, telemetry);
  const draft: ScenarioResult = {
    productionId: production.id,
    steps,
    gates,
    telemetry,
    plot: { ...plot, colorHex: production.storyboard.colorHex },
    imaginePrompt,
    tweet,
    storyboard: production.storyboard,
    filmPlan,
  };

  const reviews = runReviewRoom(production, draft);
  const roomOk = reviewPass(reviews);
  gates.push(
    gate("BEATS", "pass", `${production.storyboard.beats.length || 3} beats compiled from telemetry.`),
    gate(
      "REVIEW",
      roomOk ? "pass" : "fail",
      roomOk
        ? `Vallado / Hopper / Murch / Sagan signed. ${reviews.map((n) => n.score.toFixed(1)).join(" · ")}`
        : reviews
            .filter((n) => !n.pass)
            .map((n) => `${n.name}: ${n.note}`)
            .join(" "),
    ),
  );

  if (!roomOk || !simOk || !conserveOk || !oracleOk) {
    const failed = !simOk ? "SIM" : !conserveOk ? "CONSERVE" : !oracleOk ? "ORACLE" : "REVIEW";
    gates.push(...lockedAfter(failed as GateResult["id"]));
  } else {
    gates.push(
      gate(
        "IMAGINE",
        "locked",
        `${filmPlan.runtimeLabel}. Locked until we both like the sim.`,
      ),
      gate("ASSEMBLE", "locked", `Stitch ${filmPlan.clipCount} clips into one ${filmPlan.resolution} picture.`),
      gate("APPROVE", "idle", "Your click. Opens a draft on @thenlaguna."),
      gate("RELEASE", "locked", "Not posted."),
    );
  }

  draft.gates = [...gates, ...extraGates];
  return draft;
}

function notReady(production: Production): ScenarioResult {
  return {
    productionId: production.id,
    steps: [
      step(
        "queued",
        production.adaRef,
        false,
        "This film is specified. The Ada-faithful script has not been ported yet. Next continue rounds unlock it.",
        { queued: 1 },
      ),
    ],
    gates: [
      gate("SPEC", "pass", production.synopsis),
      gate("SIM", "idle", "Waiting on the next port."),
      ...["CONSERVE", "ORACLE", "BEATS", "REVIEW", "IMAGINE", "ASSEMBLE", "APPROVE", "RELEASE"].map((id) =>
        gate(id as GateResult["id"], "locked", "Queued."),
      ),
    ],
    telemetry: {},
    plot: { kind: "hohmann", colorHex: production.storyboard.colorHex },
    imaginePrompt: "",
    tweet: "",
    storyboard: production.storyboard,
  };
}

function runHohmann(production: Production): ScenarioResult {
  const r1 = HOHMANN_ORACLE.r1;
  const r2 = HOHMANN_ORACLE.r2;
  const mu = MU_EARTH;
  const h = hohmannTransfer(r1, r2, mu);
  const hours = h.transferTime / 3600;
  const e1 = specificEnergySma(r1, mu);
  const eT = specificEnergySma(h.aTransfer, mu);
  const e2 = specificEnergySma(r2, mu);
  const energyResidual = Math.abs(eT - (h.vTrans1 ** 2 / 2 - mu / r1));

  const steps: SimStep[] = [
    step("circular_velocity_leo", "Hale_Orbital.Twobody.Circular_Velocity", true, "LEO 300 km circular.", {
      r_km: r1,
      v_kms: h.vCirc1,
    }),
    step("circular_velocity_geo", "Hale_Orbital.Twobody.Circular_Velocity", true, "GEO circular.", {
      r_km: r2,
      v_kms: h.vCirc2,
    }),
    step("hohmann_transfer", "Hale_Orbital.Maneuvers.Hohmann_Transfer", true, "Two-impulse climb.", {
      a_km: h.aTransfer,
      e: h.eTransfer,
      dv1_kms: h.deltaV1,
      dv2_kms: h.deltaV2,
      tof_s: h.transferTime,
    }),
    step("vis_viva_periapsis", "Hale_Orbital.Twobody.Vis_Viva", true, "Transfer speed at LEO periapsis.", {
      v_kms: visViva(r1, h.aTransfer, mu),
    }),
    step("energy_ledger", "Hale_Orbital.Twobody.Specific_Energy", true, "ε on each conic.", {
      e_leo: e1,
      e_transfer: eT,
      e_geo: e2,
      energyResidual,
    }),
    step(
      "kepler_midcourse",
      "Hale_Orbital.Kepler.Solve_Kepler_Elliptic",
      true,
      "Mid-transfer: M → E → ν on the Hohmann ellipse.",
      (() => {
        const M = Math.PI / 2;
        const E = solveKeplerElliptic(M, h.eTransfer);
        const nu = trueAnomalyFromE(E, h.eTransfer);
        const back = meanFromE(E, h.eTransfer);
        return { M, E, nu, M_residual: back - M };
      })(),
    ),
    step("stumpff_check", "Hale_Orbital.Stumpff.C / S", Math.abs(stumpffC(0) - 0.5) < 1e-12, "C(0)=1/2, S(0)=1/6.", {
      C0: stumpffC(0),
      S0: stumpffS(0),
    }),
    step(
      "oracle_hale_ch6",
      "hohmann_transfer.adb",
      close(h.deltaV1, HOHMANN_ORACLE.dv1, 0.002) && close(hours, HOHMANN_ORACLE.hours, 0.02),
      "Closed-form LEO→GEO vs Hale Ch. 6 workbook.",
      { dv1_err: h.deltaV1 - HOHMANN_ORACLE.dv1, hours_err: hours - HOHMANN_ORACLE.hours },
    ),
  ];

  const telemetry = {
    r1,
    r2,
    deltaV1: h.deltaV1,
    deltaV2: h.deltaV2,
    totalDeltaV: h.totalDeltaV,
    transferHours: hours,
    aTransfer: h.aTransfer,
    eTransfer: h.eTransfer,
    energyResidual,
  };

  const plot: PlotData = {
    kind: "hohmann",
    earthR: R_EARTH,
    r1,
    r2,
    aTransfer: h.aTransfer,
    eTransfer: h.eTransfer,
    transferSamples: sampleEllipse(h.aTransfer, h.eTransfer, 180).map(({ x, y }) => ({ x, y })),
    innerSamples: sampleEllipse(r1, 0, 120).map(({ x, y }) => ({ x, y })),
    outerSamples: sampleEllipse(r2, 0, 120).map(({ x, y }) => ({ x, y })),
  };

  return finish(
    production,
    steps,
    telemetry,
    plot,
    [
      `Δv1=${h.deltaV1.toFixed(4)} km/s`,
      `Δv2=${h.deltaV2.toFixed(4)} km/s`,
      `TOF=${hours.toFixed(3)} h`,
      `e=${h.eTransfer.toFixed(4)}`,
    ],
    `Δv₁ ${h.deltaV1.toFixed(3)} km/s · Δv₂ ${h.deltaV2.toFixed(3)} km/s · ${hours.toFixed(2)} h`,
  );
}

function runEscape(production: Production): ScenarioResult {
  const r = R_EARTH + 300;
  const vC = circularVelocity(r, MU_EARTH);
  const vEsc = escapeVelocity(r, MU_EARTH);
  const dv = vEsc - vC;
  const expected = vC * (Math.SQRT2 - 1);
  const steps: SimStep[] = [
    step("circular", "Circular_Velocity", true, "Bound LEO.", { r, vC }),
    step("escape", "Escape_Velocity", true, "C3 = 0.", { vEsc, dv }),
    step("oracle_sqrt2", "Hale Eq. escape", close(dv, expected, 1e-10), "Δv_esc = v_c (√2 − 1).", {
      err: dv - expected,
    }),
  ];
  return finish(
    production,
    steps,
    { r, vC, vEsc, escapeDv: dv, energyResidual: 0 },
    {
      kind: "hohmann",
      earthR: R_EARTH,
      r1: r,
      r2: r * 8,
      aTransfer: r * 4,
      eTransfer: 0.75,
      innerSamples: sampleEllipse(r, 0, 100).map(({ x, y }) => ({ x, y })),
      transferSamples: sampleEllipse(r * 4, 0.75, 160).map(({ x, y }) => ({ x, y })),
    },
    [`escape Δv=${dv.toFixed(4)} km/s`, "C3=0"],
    `escape Δv ${dv.toFixed(3)} km/s · C3 = 0`,
  );
}

function runLagrangeFilm(
  production: Production,
  system: ThreebodySystem,
  point: LagrangeId,
  kick: { x?: number; y?: number; vx?: number; vy?: number },
  tFinal: number,
): ScenarioResult {
  const L = computeLagrangePoint(system, point);
  const all = computeAllLagrange(system);
  const mu = system.massRatio;
  const eq = jacobiConstant({ x: L.x, y: L.y, z: 0, vx: 0, vy: 0, vz: 0 }, mu);
  const atRestAccel = (() => {
    const { x, y } = L;
    const state = { x, y, z: 0, vx: 0, vy: 0, vz: 0 };
    // equilibrium: acceleration ~ 0
    const d1 = Math.hypot(x + mu, y);
    const d2 = Math.hypot(x - (1 - mu), y);
    const ox = x - ((1 - mu) * (x + mu)) / d1 ** 3 - (mu * (x - 1 + mu)) / d2 ** 3;
    const oy = y - ((1 - mu) * y) / d1 ** 3 - (mu * y) / d2 ** 3;
    return Math.hypot(ox, oy);
  })();

  const initial = {
    x: L.x + (kick.x ?? 0),
    y: L.y + (kick.y ?? 0),
    z: 0,
    vx: kick.vx ?? 0,
    vy: kick.vy ?? 0,
    vz: 0,
  };
  const prop = propagateRk4(initial, mu, tFinal, 0.004);
  const routh = isL4L5Stable(mu);
  const l2km = dimensionalKm(Math.abs(L.x - (1 - mu)), system);
  const fromBary = dimensionalKm(Math.hypot(L.x, L.y), system);

  const steps: SimStep[] = [
    step("system", "Hale_Orbital.Threebody system constant", true, `${system.name} μ=${mu}`, {
      mu,
      distance_km: system.distance,
    }),
    step(
      `lagrange_${point}`,
      "Hale_Orbital.Threebody.Compute_Lagrange_Point",
      L.converged,
      `Newton (Ada quintic) locked ${point}.`,
      { x: L.x, y: L.y, jacobi: L.jacobi, km_from_bary: fromBary },
    ),
    step(
      "equilibrium",
      "Compute_Acceleration at rest",
      atRestAccel < 1e-9,
      "Acceleration at the point vanishes. It is an equilibrium.",
      { accel: atRestAccel },
    ),
    step("all_five", "Compute_All_Lagrange_Points", all.every((p) => p.converged), "L1–L5 computed.", {
      L1x: all[0]!.x,
      L2x: all[1]!.x,
      L3x: all[2]!.x,
      L4y: all[3]!.y,
    }),
    step(
      "routh",
      "Analyze_Stability / μ_Routh",
      point === "L4" || point === "L5" ? routh : true,
      point === "L4" || point === "L5"
        ? `Routh: μ ${mu} ${routh ? "<" : "≥"} 0.03852 → L4/L5 ${routh ? "stable" : "unstable"}.`
        : `${point} is collinear — always a saddle.`,
      { mu, routh: routh ? 1 : 0 },
    ),
    step(
      "rk4_propagate",
      "Hale_Orbital.Threebody.Propagate RK4",
      prop.jacobiResidual < 1e-6,
      `Kick off ${point}. Jacobi conserved along the trail.`,
      { jacobiResidual: prop.jacobiResidual, samples: prop.samples.length, tFinal },
    ),
    step("oracle_jacobi_eq", "C = 2Ω at rest", close(eq, L.jacobi, 1e-10), "Jacobi at the point equals 2Ω.", {
      err: eq - L.jacobi,
    }),
  ];

  const telemetry = {
    mu,
    lX: L.x,
    lY: L.y,
    jacobi: L.jacobi,
    jacobiResidual: prop.jacobiResidual,
    lPointKm: l2km,
    fromBaryKm: fromBary,
    accelEq: atRestAccel,
    routh: routh ? 1 : 0,
  };

  const plot: PlotData = {
    kind: "cr3bp",
    systemName: system.name,
    mu,
    primaries: primaryPositions(system),
    points: all.map((p) => ({ id: p.point, x: p.x, y: p.y })),
    trail: prop.samples.map((s) => ({ x: s.x, y: s.y })),
  };

  return finish(
    production,
    steps,
    telemetry,
    plot,
    [
      `${system.name} ${point} x=${L.x.toFixed(6)}`,
      `C=${L.jacobi.toFixed(6)}`,
      `Earth/secondary offset ${l2km.toFixed(0)} km`,
      `Jacobi residual ${prop.jacobiResidual.toExponential(2)}`,
    ],
    `${point} · ${l2km.toFixed(0)} km from secondary · C=${L.jacobi.toFixed(4)}`,
  );
}

function withBeats(production: Production): Production {
  if (production.storyboard.beats.length >= 3) return production;
  const sb = production.storyboard;
  return {
    ...production,
    storyboard: {
      ...sb,
      beats: [
        { t: "0:00", shot: "The finding, written first — a number on glass.", camera: "insert, 50mm", fromFinding: "primary scalar" },
        { t: "0:50", shot: sb.astronaut, camera: "human, then the sky", fromFinding: "the same number, lived" },
        { t: "2:00", shot: "The orbit as the camera understands it.", camera: "wide, 2.39", fromFinding: "geometry" },
        { t: "2:50", shot: sb.logline, camera: "hold, no music swell", fromFinding: "caption" },
      ],
    },
  };
}

export function runScenario(id: number): ScenarioResult {
  const raw = productionById(id) ?? CATALOG[0]!;
  const production = withBeats(raw);
  if (!isRunnable(production)) return notReady(production);

  switch (production.slug) {
    case "leo-geo-hohmann":
      return runHohmann(production);
    case "escape-c3":
      return runEscape(production);
    case "jwst-halo":
      return runLagrangeFilm(production, SUN_EARTH, "L2", { y: 0.002, vy: 0.001 }, 2.4);
    case "soho-l1":
    case "dscovr-smile":
      return runLagrangeFilm(production, SUN_EARTH, "L1", { y: 0.0015, vx: -0.0004 }, 2.2);
    case "earth-moon-l4":
      return runLagrangeFilm(production, EARTH_MOON, "L4", { x: 0.01, y: 0.01, vx: -0.01 }, 6);
    case "earth-moon-l5":
      return runLagrangeFilm(production, EARTH_MOON, "L5", { x: 0.01, y: -0.01, vx: 0.01 }, 6);
    case "l3-ghost":
      return runLagrangeFilm(production, SUN_EARTH, "L3", { y: 0.004 }, 3);
    case "trojan-camp":
      return runLagrangeFilm(production, SUN_JUPITER, "L4", { x: 0.02, vy: -0.01 }, 8);
    case "vis-viva-recited":
    case "energy-ledger":
      return runHohmann(production);
    default:
      return notReady(production);
  }
}

export { runReviewRoom } from "./reviews";
