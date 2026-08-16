import { GATE_ORDER, type GateId, type GateResult, type GateStatus, type SimStep } from "./types";

export function gate(
  id: GateId,
  status: GateStatus,
  detail: string,
  residual?: number,
): GateResult {
  return { id, status, detail, residual };
}

export function lockedAfter(failed: GateId): GateResult[] {
  const i = GATE_ORDER.indexOf(failed);
  return GATE_ORDER.slice(i + 1).map((id) =>
    gate(id, "locked", `Locked until ${failed} passes.`),
  );
}

export function finiteValues(values: Record<string, number | string>): boolean {
  return Object.values(values).every((v) =>
    typeof v === "string" ? v.length > 0 : Number.isFinite(v),
  );
}

export function allStepsOk(steps: SimStep[]): boolean {
  return steps.length > 0 && steps.every((s) => s.ok && finiteValues(s.values));
}

export function worstResidual(steps: SimStep[], keys: string[]): number {
  let worst = 0;
  for (const s of steps) {
    for (const k of keys) {
      const v = s.values[k];
      if (typeof v === "number") worst = Math.max(worst, Math.abs(v));
    }
  }
  return worst;
}
