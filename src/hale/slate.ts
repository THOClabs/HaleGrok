import { CATALOG } from "./catalog";
import type { Production } from "./types";

/** First continue-round: eight films, already runnable, mixed two-body + three-body. */
export const ROUND_1_SLUGS = [
  "leo-geo-hohmann",
  "escape-c3",
  "jwst-halo",
  "soho-l1",
  "earth-moon-l4",
  "earth-moon-l5",
  "l3-ghost",
  "trojan-camp",
] as const;

export const RUNNABLE_SLUGS = new Set<string>([
  ...ROUND_1_SLUGS,
  "vis-viva-recited",
  "energy-ledger",
  "dscovr-smile",
]);

export function isRunnable(p: Production): boolean {
  return p.runnable || RUNNABLE_SLUGS.has(p.slug);
}

export function slateForRound(round = 1): Production[] {
  if (round === 1) {
    return ROUND_1_SLUGS.map((slug) => CATALOG.find((p) => p.slug === slug)).filter(
      (p): p is Production => Boolean(p),
    );
  }
  const start = 8 + (round - 2) * 8;
  return CATALOG.filter((p) => !ROUND_1_SLUGS.includes(p.slug as (typeof ROUND_1_SLUGS)[number])).slice(
    start,
    start + 8,
  );
}

export function currentRound(): number {
  return 1;
}
