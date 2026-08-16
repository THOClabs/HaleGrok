/**
 * Review agents — a small room that watches the cut before Imagine is allowed.
 * They polish for an audience that likes orbital mechanics, not trailer noise.
 */
import type { Production, ScenarioResult } from "./types";

export type ReviewerId = "vallado" | "hopper" | "murch" | "sagan";

export type ReviewNote = {
  id: ReviewerId;
  name: string;
  desk: string;
  score: number;
  pass: boolean;
  note: string;
  polish: string;
};

export const REVIEWERS: Array<{
  id: ReviewerId;
  name: string;
  desk: string;
}> = [
  { id: "vallado", name: "Vallado", desk: "numbers" },
  { id: "hopper", name: "Hopper", desk: "audience" },
  { id: "murch", name: "Murch", desk: "cut" },
  { id: "sagan", name: "Sagan", desk: "wonder" },
];

function vallado(p: Production, r: ScenarioResult): ReviewNote {
  const residual = r.gates.find((g) => g.id === "CONSERVE")?.residual ?? 1;
  const oracle = r.gates.find((g) => g.id === "ORACLE");
  const simOk = r.gates.find((g) => g.id === "SIM")?.status === "pass";
  const pass = simOk && residual < 1e-6 && oracle?.status === "pass";
  return {
    id: "vallado",
    name: "Vallado",
    desk: "numbers",
    score: pass ? 9.4 : 4.1,
    pass,
    note: pass
      ? `Residuals sit under 1e-6. ${p.adaRef.split("/")[0]} agrees with the TypeScript port. I would sign the memo.`
      : `I will not send this to a camera. SIM/ORACLE/CONSERVE is not clean (residual ${residual}).`,
    polish: pass
      ? "Keep the number on screen for a full breath. Do not round past the oracle."
      : "Re-run the Ada-faithful steps. No picture until the residual dies.",
  };
}

function hopper(p: Production, _r: ScenarioResult): ReviewNote {
  const hasHuman = p.storyboard.astronaut.length > 40;
  const hasColor = p.storyboard.colorName.length > 0;
  const hasLog = p.storyboard.logline.length > 12;
  const pass = hasHuman && hasColor && hasLog;
  return {
    id: "hopper",
    name: "Hopper",
    desk: "audience",
    score: pass ? 8.8 : 5.0,
    pass,
    note: pass
      ? `I would watch this. The color is ${p.storyboard.colorName}. The person is doing one specific thing. That is enough.`
      : "Nobody stays for a diagram. Put a person in a room with a reason.",
    polish: `Open on the human, not the spacecraft. Hold ${p.storyboard.colorName} for the whole film — do not 'add space blue.'`,
  };
}

function murch(p: Production, _r: ScenarioResult): ReviewNote {
  const beats = p.storyboard.beats.length;
  const pass = beats >= 3 && p.targetMinutes >= 2 && p.targetMinutes <= 6;
  return {
    id: "murch",
    name: "Murch",
    desk: "cut",
    score: pass ? 8.6 : 5.2,
    pass,
    note: pass
      ? `${beats} beats in ${p.targetMinutes} minutes. Cut on the finding, not on the flare. Silence after the burn.`
      : `Either too few beats (${beats}) or the runtime is wrong. A few minutes, not a lecture.`,
    polish: "Leave 8 frames of black after each impulse. The audience will lean in.",
  };
}

function sagan(p: Production, r: ScenarioResult): ReviewNote {
  const tweetHasDigit = /\d/.test(r.tweet);
  const findings = Object.keys(r.telemetry).length;
  const pass = tweetHasDigit && findings >= 3 && p.storyboard.logline.length > 0;
  return {
    id: "sagan",
    name: "Sagan",
    desk: "wonder",
    score: pass ? 9.1 : 4.8,
    pass,
    note: pass
      ? `Wonder without lying. ${findings} numbers earned the awe. The caption tells the truth.`
      : "Awe that is not numbered is advertising. Put a finding in the sentence.",
    polish: `Say the number in the voiceover once, then never again. Let ${p.storyboard.colorName} do the rest.`,
  };
}

export function runReviewRoom(production: Production, result: ScenarioResult): ReviewNote[] {
  return [
    vallado(production, result),
    hopper(production, result),
    murch(production, result),
    sagan(production, result),
  ];
}

export function reviewPass(notes: ReviewNote[]): boolean {
  return notes.every((n) => n.pass);
}
