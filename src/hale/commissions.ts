/** Pictures we have both liked. Source of truth for the desk, not just localStorage. */
export type Commission = {
  productionId: number;
  slug: string;
  likedAt: string;
  clipCount: number;
  minutes: number;
  nextClip: number;
  note: string;
};

export const COMMISSIONS: Commission[] = [
  {
    productionId: 1,
    slug: "leo-geo-hohmann",
    likedAt: "2026-08-16T13:55:00Z",
    clipCount: 48,
    minutes: 12,
    nextClip: 3,
    note: "The Climb is in. Opening reel: clips 1–2. 46 remain.",
  },
];

export function commissionFor(id: number): Commission | undefined {
  return COMMISSIONS.find((c) => c.productionId === id);
}
