export type GateId =
  | "SPEC"
  | "SIM"
  | "CONSERVE"
  | "ORACLE"
  | "BEATS"
  | "REVIEW"
  | "IMAGINE"
  | "ASSEMBLE"
  | "APPROVE"
  | "RELEASE";

export const GATE_ORDER: GateId[] = [
  "SPEC",
  "SIM",
  "CONSERVE",
  "ORACLE",
  "BEATS",
  "REVIEW",
  "IMAGINE",
  "ASSEMBLE",
  "APPROVE",
  "RELEASE",
];

export type GateStatus = "idle" | "running" | "pass" | "fail" | "locked";

export type GateResult = {
  id: GateId;
  status: GateStatus;
  detail: string;
  residual?: number;
};

export type SimStep = {
  name: string;
  source: string;
  ok: boolean;
  detail: string;
  values: Record<string, number | string>;
};

export type ProductionFamily =
  | "two-body"
  | "maneuver"
  | "interplanetary"
  | "lambert"
  | "cr3bp"
  | "observatory";

/** One cinematic beat — born from a number the sim actually produced. */
export type StoryBeat = {
  t: string;
  shot: string;
  camera: string;
  fromFinding: string;
};

export type Storyboard = {
  /** Film color — one wash that owns the whole piece. */
  colorName: string;
  colorHex: string;
  accentHex: string;
  /** The human event. Always a person in the picture. */
  astronaut: string;
  logline: string;
  beats: StoryBeat[];
};

export type Production = {
  id: number;
  slug: string;
  title: string;
  family: ProductionFamily;
  haleRef: string;
  adaRef: string;
  synopsis: string;
  runnable: boolean;
  shots: number;
  targetMinutes: number;
  storyboard: Storyboard;
};

export type PlotKind = "hohmann" | "cr3bp";

export type PlotData = {
  kind: PlotKind;
  earthR?: number;
  r1?: number;
  r2?: number;
  aTransfer?: number;
  eTransfer?: number;
  transferSamples?: Array<{ x: number; y: number }>;
  innerSamples?: Array<{ x: number; y: number }>;
  outerSamples?: Array<{ x: number; y: number }>;
  systemName?: string;
  mu?: number;
  primaries?: { p1: { x: number; y: number }; p2: { x: number; y: number } };
  points?: Array<{ id: string; x: number; y: number }>;
  trail?: Array<{ x: number; y: number }>;
  colorHex?: string;
};

export type ScenarioResult = {
  productionId: number;
  steps: SimStep[];
  gates: GateResult[];
  telemetry: Record<string, number>;
  plot: PlotData;
  imaginePrompt: string;
  tweet: string;
  storyboard: Storyboard;
};

export const X_HANDLE = "thenlaguna";
