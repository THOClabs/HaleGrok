import type { Production, ScenarioResult, StoryBeat } from "./types";

function fmt(n: number, digits = 4): string {
  if (!Number.isFinite(n)) return "—";
  if (Math.abs(n) >= 1000) return n.toLocaleString("en-US", { maximumFractionDigits: 1 });
  return n.toPrecision(digits);
}

function beatLine(b: StoryBeat): string {
  return `${b.t} — ${b.shot} Camera: ${b.camera}. The number on screen is ${b.fromFinding}.`;
}

/** Imagine prompt compiled ONLY from sim findings + the storyboard. */
export function compileImaginePrompt(
  production: Production,
  telemetry: Record<string, number>,
  findings: string[],
): string {
  const sb = production.storyboard;
  const numbers = Object.entries(telemetry)
    .slice(0, 12)
    .map(([k, v]) => `${k}=${fmt(v)}`)
    .join(", ");

  const beats = sb.beats.map(beatLine).join("\n");

  return [
    `Photoreal 4K cinema, 2.39:1, IMAX-grade space photography.`,
    `Color wash: ${sb.colorName} (${sb.colorHex}) with ${sb.accentHex} edge light. No other palette.`,
    `Human event: ${sb.astronaut}`,
    `Logline: ${sb.logline}`,
    `This image and every later shot MUST be consistent with these computed findings: ${findings.join("; ")}.`,
    `Telemetry (do not invent different numbers): ${numbers}.`,
    `Story beats:\n${beats}`,
    `No on-screen title cards. No UI chrome. No illegible fake readouts. Physical light only.`,
    `Hale / Ada provenance: ${production.haleRef}; ${production.adaRef}.`,
  ].join("\n");
}

export function compileTweet(
  production: Production,
  telemetry: Record<string, number>,
  headlineNumber: string,
): string {
  const id = String(production.id).padStart(3, "0");
  return [
    `HaleGrok ${id} — ${production.title}`,
    headlineNumber,
    `${production.haleRef}`,
    `sim-verified · storyboard locked · waiting on the cut`,
    `#HaleGrok #astrodynamics`,
  ].join("\n");
}

export function headlineFrom(result: Pick<ScenarioResult, "telemetry" | "productionId">): string {
  const t = result.telemetry;
  if (t.deltaV1 != null && t.deltaV2 != null) {
    return `Δv₁ ${fmt(t.deltaV1, 4)} km/s · Δv₂ ${fmt(t.deltaV2, 4)} km/s · ${fmt((t.transferHours ?? 0), 3)} h`;
  }
  if (t.lPointKm != null) {
    return `${t.pointName ?? "L"} · ${fmt(t.lPointKm, 4)} km · C=${fmt(t.jacobi ?? 0, 6)}`;
  }
  if (t.escapeDv != null) {
    return `escape Δv ${fmt(t.escapeDv, 4)} km/s · C3 = 0`;
  }
  const first = Object.entries(t)[0];
  return first ? `${first[0]} ${fmt(Number(first[1]))}` : "sim complete";
}
