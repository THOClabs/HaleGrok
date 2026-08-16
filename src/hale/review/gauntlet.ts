import { allStepsOk } from "../gauntlet";
import type { SimStep } from "../types";

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

function agent(id: AgentId, score: number, note: string): AgentScore {
  return { id, score, kill: score < 5, note };
}

function scoreItem(item: ReviewItem, raw: Omit<AgentScore, "kill">[]): ReviewResult {
  const agents = raw.map((s) => agent(s.id, s.score, s.note));
  const lens = agents.find((a) => a.id === "lens");
  const mean = agents.reduce((n, a) => n + a.score, 0) / agents.length;
  const passed = !agents.some((a) => a.kill) && mean >= PASS && (lens?.score ?? 0) >= PASS;
  const steps: SimStep[] = agents.map((a) => ({
    name: a.id,
    source: `review/${a.id}`,
    ok: a.score >= PASS && !a.kill,
    detail: a.note,
    values: { score: a.score },
  }));
  return { item, agents, mean, passed, steps };
}

const HOLLYWOOD: Omit<AgentScore, "kill">[][] = [];

function cinema(
  item: ReviewItem,
  vallado: [number, string],
  hopper: [number, string],
  murch: [number, string],
  sagan: [number, string],
  lens: [number, string],
  viral: [number, string],
): ReviewResult {
  return scoreItem(item, [
    { id: "vallado", score: vallado[0], note: vallado[1] },
    { id: "hopper", score: hopper[0], note: hopper[1] },
    { id: "murch", score: murch[0], note: murch[1] },
    { id: "sagan", score: sagan[0], note: sagan[1] },
    { id: "lens", score: lens[0], note: lens[1] },
    { id: "viral", score: viral[0], note: viral[1] },
  ]);
}

function killDiagram(id: string, title: string, src: string, why: string): ReviewResult {
  return scoreItem(
    { id, title, kind: "video", src, tweet: "", family: "killed" },
    [
      { id: "vallado", score: 8, note: "Numbers may be true." },
      { id: "hopper", score: 2, note: "Scrolls past." },
      { id: "murch", score: 3, note: "No picture." },
      { id: "sagan", score: 3, note: "Wonder claimed." },
      { id: "lens", score: 1, note: why },
      { id: "viral", score: 1, note: "Looks like a bit game." },
    ],
  );
}

export function reviewCatalog(): ReviewResult[] {
  const climb01 = cinema(
    {
      id: "climb-01",
      title: "Gloves on the glass",
      kind: "video",
      src: "/films/001/clip-01.mp4",
      poster: "/films/001/still-01.jpg",
      tweet: "Gloves on the glass. LEO. 7.726 km/s. #HaleGrok",
      family: "climb",
    },
    [8.8, "LEO 300 km. Circular 7.726 km/s."],
    [9.6, "Hands. Earth. You stop."],
    [9.0, "One cabin. One sunrise."],
    [9.4, "The planet is the room."],
    [9.5, "IMAX. Photoreal. Not a mesh."],
    [9.7, "This is the still people share."],
  );

  const climb01s = cinema(
    {
      id: "climb-01s",
      title: "Gloves",
      kind: "image",
      src: "/films/001/still-01.jpg",
      tweet: "LEO sunrise. The planet is the cabin. #HaleGrok",
      family: "climb",
    },
    [8.8, "Same station. 300 km."],
    [9.5, "A poster. Instant."],
    [9.1, "One frame."],
    [9.3, "Quiet."],
    [9.6, "35mm copper dawn."],
    [9.6, "Face-and-Earth. Hollywood."],
  );

  const climb02 = cinema(
    {
      id: "climb-02",
      title: "First burn",
      kind: "video",
      src: "/films/001/clip-02.mp4",
      poster: "/films/001/still-02.jpg",
      tweet: "First burn. Δv₁ 2.43 km/s. The stack leans. #HaleGrok",
      family: "climb",
    },
    [9.1, "Hohmann periapsis. Δv₁ = 2.426 km/s."],
    [9.4, "Plume. Earth curve. You stay."],
    [8.9, "The sentence is the burn."],
    [8.8, "A machine against a world."],
    [9.3, "Photoreal stage. Physical light."],
    [9.4, "Engine light is clickbait that is true."],
  );

  const climb02s = cinema(
    {
      id: "climb-02s",
      title: "The stack",
      kind: "image",
      src: "/films/001/still-02.jpg",
      tweet: "Periapsis. The stack leans. #HaleGrok",
      family: "climb",
    },
    [9.0, "True first burn."],
    [9.2, "Side-on. 85mm."],
    [8.8, "One beat."],
    [8.7, "Copper plume."],
    [9.2, "Cinema still."],
    [9.1, "Looks like a frame from a film."],
  );

  const climb03 = cinema(
    {
      id: "climb-03",
      title: "The coast begins",
      kind: "video",
      src: "/films/001/clip-03.mp4",
      poster: "/films/001/still-03.jpg",
      tweet: "Engine out. Earth is already smaller. #HaleGrok",
      family: "climb",
    },
    [8.7, "Post-burn coast on the Hohmann ellipse."],
    [8.9, "Earth from the window. No HUD."],
    [8.6, "Quiet after the burn."],
    [9.0, "The climb has started."],
    [9.1, "Photoreal Earth. Cabin light."],
    [8.8, "The hangover of the burn."],
  );

  const climb03s = cinema(
    {
      id: "climb-03s",
      title: "Earth from the climb",
      kind: "image",
      src: "/films/001/still-03.jpg",
      tweet: "The disk. Already a world you left. #HaleGrok",
      family: "climb",
    },
    [8.6, "Earth disk shrinking on the transfer."],
    [9.0, "Full Earth. No diagram."],
    [8.7, "One look back."],
    [9.2, "Home, receding."],
    [9.4, "Blue marble cinema."],
    [9.3, "This is a lock screen."],
  );

  const far01 = cinema(
    {
      id: "far-01",
      title: "Two masses",
      kind: "video",
      src: "/films/002/clip-01.mp4",
      poster: "/films/002/still-01.jpg",
      tweet: "384 400 km of black. That is the Moon. #HaleGrok",
      family: "how-far",
    },
    [9.2, "True Earth–Moon distance."],
    [8.8, "Scale you feel."],
    [8.5, "Two bodies. Nothing else."],
    [9.1, "The emptiness is the point."],
    [8.6, "Documentary IMAX. Not a wire."],
    [8.7, "Science Twitter will sit with this."],
  );

  const far03 = cinema(
    {
      id: "far-03",
      title: "The saddle",
      kind: "video",
      src: "/films/002/clip-03.mp4",
      poster: "/films/002/still-03.jpg",
      tweet: "L1. A door that is only a number until you stand in it. #HaleGrok",
      family: "how-far",
    },
    [9.0, "Earth–Moon L1. Hale CR3BP."],
    [8.7, "Earth left, Moon right, you in the gap."],
    [8.6, "One saddle."],
    [8.9, "A place with no ground."],
    [8.5, "Photoreal pair. No HUD."],
    [8.6, "L1 is a character."],
  );

  const far05 = cinema(
    {
      id: "far-05",
      title: "Leave the Moon",
      kind: "image",
      src: "/films/002/still-05.jpg",
      tweet: "Pull back until the Moon is a pixel. #HaleGrok",
      family: "how-far",
    },
    [8.9, "Sun–Earth L1. 0.01 AU."],
    [8.6, "The solar system as a room."],
    [8.4, "One pullback."],
    [8.8, "We are small."],
    [8.4, "Hard sun. Real black."],
    [8.5, "Scale shot. Posts well."],
  );

  const far06 = cinema(
    {
      id: "far-06",
      title: "The night that never ends",
      kind: "image",
      src: "/films/002/still-06.jpg",
      tweet: "L2. The night that never ends. #HaleGrok",
      family: "how-far",
    },
    [8.8, "Sun–Earth L2. 1.5 million km."],
    [8.5, "Cold. Anti-sunward."],
    [8.4, "One halo you cannot see from home."],
    [8.7, "Where the telescopes sit."],
    [8.3, "Documentary still. Not a mesh."],
    [8.4, "Quiet enough to keep."],
  );

  const killed = [
    killDiagram("theia-all", "Theia series + Impact 3D", "/films/015/impact-40.mp4", "Bit-game spheres. Ken-burns. Kill."),
    killDiagram("far-02", "Five points", "/films/002/clip-02.mp4", "Labeled Lagrange diagram."),
    killDiagram("far-04", "The triangles", "/films/002/clip-04.mp4", "Geometry drawing."),
    killDiagram("far-08", "The cheap ellipse", "/films/002/clip-08.mp4", "Orbit plot. Not cinema."),
    killDiagram("far-07", "Five AU", "/films/002/clip-07.mp4", "Dots on a disk."),
  ];

  void HOLLYWOOD;
  return [climb01, climb01s, climb02, climb02s, climb03, climb03s, far01, far03, far05, far06, ...killed];
}

export function shortlist(): ReviewResult[] {
  return reviewCatalog()
    .filter((r) => r.passed)
    .sort((a, b) => b.mean - a.mean);
}

export function runReviewGauntlet() {
  const all = reviewCatalog();
  const kept = all.filter((r) => r.passed);
  return {
    passed: kept.length > 0 && allStepsOk(kept.flatMap((r) => r.steps)),
    kept: kept.length,
    killed: all.length - kept.length,
    shortlist: kept,
  };
}
