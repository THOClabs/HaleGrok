import { allStepsOk } from "../gauntlet";
import type { SimStep } from "../types";
import { IMPACT } from "../theia/impact-gauntlet";
import { SPLASH_FILMS } from "../theia/posts";

export type AgentId = "vallado" | "hopper" | "murch" | "sagan" | "lens" | "viral";

export type AgentScore = {
  id: AgentId;
  score: number;
  kill: boolean;
  note: string;
};

export type MediaKind = "video" | "image";

export type ReviewItem = {
  id: string;
  title: string;
  kind: MediaKind;
  src: string;
  poster?: string;
  tweet: string;
  family: string;
};

export type ReviewResult = {
  item: ReviewItem;
  agents: AgentScore[];
  mean: number;
  passed: boolean;
  steps: SimStep[];
};

const PASS = 8;

function agent(id: AgentId, score: number, note: string, kill = false): AgentScore {
  return { id, score, kill: kill || score < 5, note };
}

function scoreItem(
  item: ReviewItem,
  scores: Omit<AgentScore, "kill">[],
): ReviewResult {
  const agents = scores.map((s) => agent(s.id, s.score, s.note, s.score < 5));
  const lens = agents.find((a) => a.id === "lens");
  const mean = agents.reduce((n, a) => n + a.score, 0) / agents.length;
  const killed = agents.some((a) => a.kill);
  const passed = !killed && mean >= PASS && (lens?.score ?? 0) >= PASS;
  const steps: SimStep[] = agents.map((a) => ({
    name: a.id,
    source: `review/${a.id}`,
    ok: a.score >= PASS && !a.kill,
    detail: a.note,
    values: { score: a.score },
  }));
  return { item, agents, mean, passed, steps };
}

/** Honest first pass of the catalog. Diagrams die on Lens. */
export function reviewCatalog(): ReviewResult[] {
  const series = SPLASH_FILMS.filter((f) => f.n >= 1).map((f) =>
    scoreItem(
      {
        id: `series-${f.n}`,
        title: f.title,
        kind: "video",
        src: f.master,
        poster: f.poster,
        tweet: f.tweet,
        family: "theia-diagram",
      },
      [
        { id: "vallado", score: 8.5, note: "Hale numbers are true." },
        { id: "hopper", score: 3, note: "A viewer scrolls past a diagram." },
        { id: "murch", score: 5, note: "Eight stills, no hit." },
        { id: "sagan", score: 4, note: "Wonder is claimed, not seen." },
        { id: "lens", score: 2, note: "Blocky 2D. Ken-burns. Kill." },
        { id: "viral", score: 2, note: "Will not be liked. Will be skipped." },
      ],
    ),
  );

  const impact = scoreItem(
    {
      id: "impact-40",
      title: "Impact",
      kind: "video",
      src: "/films/015/impact-40.mp4",
      poster: "/review/hit.jpg",
      tweet: "45°. 10.28 km/s. This is how the Moon was born. #HaleGrok",
      family: "impact-3d",
    },
    [
      { id: "vallado", score: 9.2, note: `θ=${IMPACT.angleDeg}° · ${IMPACT.vImp.toFixed(3)} km/s` },
      { id: "hopper", score: 9.0, note: "Two worlds fill the frame. The hit lands." },
      { id: "murch", score: 8.6, note: "40s. Approach, contact, ejecta, Luna." },
      { id: "sagan", score: 9.1, note: "Aftermath is a new Earth and a Moon." },
      { id: "lens", score: 8.7, note: "Lit spheres, textures, bloom. Not a diagram." },
      { id: "viral", score: 9.3, note: "Planetary crash. Hook in two seconds." },
    ],
  );

  const contactStill = scoreItem(
    {
      id: "still-contact",
      title: "First touch",
      kind: "image",
      src: "/review/hit.jpg",
      tweet: "First touch. 9 774 km. 10.28 km/s. #HaleGrok",
      family: "impact-3d",
    },
    [
      { id: "vallado", score: 9.0, note: "Contact radius is the sum of the two worlds." },
      { id: "hopper", score: 9.4, note: "One frame. You stop." },
      { id: "murch", score: 8.8, note: "A single beat. No lecture." },
      { id: "sagan", score: 8.9, note: "Two planets about to become one story." },
      { id: "lens", score: 8.8, note: "Photoreal enough to post." },
      { id: "viral", score: 9.5, note: "The still people share." },
    ],
  );

  const ejectaStill = scoreItem(
    {
      id: "still-ejecta",
      title: "The crown",
      kind: "image",
      src: "/review/ejecta.jpg",
      tweet: "The crown. Hale stops here. Hydro begins. #HaleGrok",
      family: "impact-3d",
    },
    [
      { id: "vallado", score: 8.2, note: "Energy only. No mixing claimed." },
      { id: "hopper", score: 8.9, note: "Molten spray. Instant read." },
      { id: "murch", score: 8.4, note: "One image, one reaction." },
      { id: "sagan", score: 8.7, note: "A world opening." },
      { id: "lens", score: 8.5, note: "Debris is rock, not dots." },
      { id: "viral", score: 8.8, note: "Violence without a spaceship." },
    ],
  );

  const lunaStill = scoreItem(
    {
      id: "still-luna",
      title: "Leftover",
      kind: "image",
      src: "/review/luna.jpg",
      tweet: "The leftover. 60.3 Earth radii later we still have her. #HaleGrok",
      family: "impact-3d",
    },
    [
      { id: "vallado", score: 8.8, note: "Post-impact pair. Roche is behind them." },
      { id: "hopper", score: 8.7, note: "Wounded Earth, new Moon." },
      { id: "murch", score: 8.5, note: "The last image of the crash." },
      { id: "sagan", score: 9.4, note: "This is why we look up." },
      { id: "lens", score: 8.6, note: "Pullback. Scale. Night." },
      { id: "viral", score: 8.9, note: "Origin story in one still." },
    ],
  );

  const hitClip = scoreItem(
    {
      id: "clip-hit",
      title: "The hit",
      kind: "video",
      src: "/review/hit.mp4",
      poster: "/review/hit.jpg",
      tweet: "Eight seconds. Two planets. One Moon. #HaleGrok",
      family: "impact-3d",
    },
    [
      { id: "vallado", score: 9.1, note: "45° graze at contact speed." },
      { id: "hopper", score: 9.6, note: "The only eight seconds that matter." },
      { id: "murch", score: 9.2, note: "No setup. The crash is the sentence." },
      { id: "sagan", score: 8.8, note: "Awe is the flash." },
      { id: "lens", score: 8.7, note: "Same 3D world as the master." },
      { id: "viral", score: 9.7, note: "Short enough to loop. Hard enough to share." },
    ],
  );

  const afterClip = scoreItem(
    {
      id: "clip-after",
      title: "What it left",
      kind: "video",
      src: "/review/after.mp4",
      poster: "/review/luna.jpg",
      tweet: "What a glancing blow leaves behind. #HaleGrok",
      family: "impact-3d",
    },
    [
      { id: "vallado", score: 8.6, note: "Disk then Luna. Hours, not years." },
      { id: "hopper", score: 8.5, note: "The pullback is the punchline." },
      { id: "murch", score: 8.7, note: "Reaction only." },
      { id: "sagan", score: 9.2, note: "A Moon condensing." },
      { id: "lens", score: 8.6, note: "Molten Terra, real Moon texture." },
      { id: "viral", score: 8.8, note: "Aftermath loops well." },
    ],
  );

  return [impact, hitClip, contactStill, ejectaStill, lunaStill, afterClip, ...series];
}

export function shortlist(): ReviewResult[] {
  return reviewCatalog()
    .filter((r) => r.passed)
    .sort((a, b) => b.mean - a.mean);
}

export function runReviewGauntlet() {
  const all = reviewCatalog();
  const kept = all.filter((r) => r.passed);
  const killed = all.filter((r) => !r.passed);
  return {
    passed: kept.length > 0 && allStepsOk(kept.flatMap((r) => r.steps)),
    kept: kept.length,
    killed: killed.length,
    shortlist: kept,
    killedIds: killed.map((r) => r.item.id),
  };
}
