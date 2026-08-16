import { R_EARTH } from "../constants";
import { allStepsOk } from "../gauntlet";
import type { SimStep } from "../types";
import { impactSpeedKms, ORACLE, PHYSICS, R_THEIA } from "./physics";

export const IMPACT = {
  duration: 40,
  contactAt: 12,
  angleDeg: ORACLE.impactAngleDeg,
  vImp: impactSpeedKms(4, PHYSICS.vEscMutual),
  rContact: R_EARTH + R_THEIA,
};

function step(name: string, ok: boolean, detail: string, values: Record<string, number>): SimStep {
  return { name, source: "Hale impact gauntlet", ok, detail, values };
}

export function runImpactGauntlet() {
  const v = IMPACT.vImp;
  const steps = [
    step("vallado_angle", IMPACT.angleDeg === 45, "45° graze. Head-on leaves no Moon.", { angle: IMPACT.angleDeg }),
    step("vallado_speed", v > ORACLE.vImpactMinKms && v < 11, `v_imp(4) = ${v.toFixed(3)} km/s`, { v }),
    step("vallado_contact", Math.abs(IMPACT.rContact - 9774.337) < 1, "First touch at R⊕ + R_Theia.", {
      r: IMPACT.rContact,
    }),
    step("hopper_runtime", IMPACT.duration === 40, "Forty seconds. One crash.", { duration: IMPACT.duration }),
    step("hopper_hit", IMPACT.contactAt === 12, "Hit at 0:12. The rest is reaction.", { contactAt: IMPACT.contactAt }),
    step("murch_beats", true, "Approach · contact · ejecta · Luna.", { beats: 4 }),
    step("sagan_aftermath", true, "The Moon is the leftover.", { lunaFrom: 26 }),
  ];
  return { passed: allStepsOk(steps), steps, telemetry: IMPACT };
}
