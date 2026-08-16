import { create } from "zustand";
import { persist } from "zustand/middleware";
import { CATALOG } from "@/hale/catalog";
import { runReviewRoom, type ReviewNote } from "@/hale/reviews";
import { runScenario } from "@/hale/scenarios";
import { slateForRound } from "@/hale/slate";
import type { ScenarioResult } from "@/hale/types";

type DeskState = {
  selectedId: number;
  result: ScenarioResult | null;
  reviews: ReviewNote[];
  running: boolean;
  approved: Record<number, { at: string; tweet: string }>;
  select: (id: number) => void;
  runSelected: () => void;
  approve: (id: number, tweet: string) => void;
};

const first = slateForRound(1)[0] ?? CATALOG[0]!;

export const useDesk = create<DeskState>()(
  persist(
    (set, get) => ({
      selectedId: first.id,
      result: null,
      reviews: [],
      running: false,
      approved: {},
      select: (id) => set({ selectedId: id, result: null, reviews: [] }),
      runSelected: () => {
        const id = get().selectedId;
        set({ running: true });
        const result = runScenario(id);
        const production = CATALOG.find((p) => p.id === id)!;
        const reviews = result.steps[0]?.ok ? runReviewRoom(production, result) : [];
        set({ result, reviews, running: false });
      },
      approve: (id, tweet) =>
        set((s) => ({
          approved: { ...s.approved, [id]: { at: new Date().toISOString(), tweet } },
        })),
    }),
    { name: "halegrok-desk", partialize: (s) => ({ selectedId: s.selectedId, approved: s.approved }) },
  ),
);
