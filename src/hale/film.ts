/**
 * Long 4K film plan.
 *
 * Imagine gives ~15s clips. A HaleGrok film is many clips, assembled after
 * you and I both like the sim. Nothing is requested until that handshake.
 */
import type { Production, StoryBeat } from "./types";

export const CLIP_SECONDS = 15;
export const FILM_RESOLUTION = "4K";
export const FILM_ASPECT = "2.39:1";

/** Flagship pictures — the long ones. */
export const LONG_SLUGS = new Set([
  "leo-geo-hohmann",
  "jwst-halo",
  "earth-mars",
  "earth-moon-l4",
  "soho-l1",
]);

export type FilmClip = {
  index: number;
  tStart: string;
  durationSec: number;
  beat: StoryBeat;
  promptSeed: string;
};

export type FilmPlan = {
  resolution: typeof FILM_RESOLUTION;
  aspect: typeof FILM_ASPECT;
  targetMinutes: number;
  clipSeconds: number;
  clipCount: number;
  runtimeLabel: string;
  clips: FilmClip[];
  handshake: string;
};

function padTime(totalSec: number): string {
  const m = Math.floor(totalSec / 60);
  const s = totalSec % 60;
  return `${m}:${String(s).padStart(2, "0")}`;
}

export function targetMinutesFor(production: Production): number {
  if (LONG_SLUGS.has(production.slug)) return 12;
  return Math.max(production.targetMinutes, 8);
}

export function compileFilmPlan(
  production: Production,
  findings: string[],
  telemetry: Record<string, number>,
): FilmPlan {
  const minutes = targetMinutesFor(production);
  const clipCount = Math.round((minutes * 60) / CLIP_SECONDS);
  const beats = production.storyboard.beats.length
    ? production.storyboard.beats
    : [
        {
          t: "0:00",
          shot: production.storyboard.astronaut,
          camera: "wide",
          fromFinding: "primary",
        },
      ];

  const clips: FilmClip[] = [];
  for (let i = 0; i < clipCount; i++) {
    const beat = beats[i % beats.length]!;
    const finding = findings[i % Math.max(findings.length, 1)] ?? beat.fromFinding;
    clips.push({
      index: i + 1,
      tStart: padTime(i * CLIP_SECONDS),
      durationSec: CLIP_SECONDS,
      beat,
      promptSeed: [
        `${FILM_RESOLUTION} ${FILM_ASPECT} cinema. Color wash ${production.storyboard.colorName}.`,
        beat.shot,
        `Camera: ${beat.camera}.`,
        `On-screen number from the Hale script: ${finding}.`,
        `Do not invent different physics.`,
      ].join(" "),
    });
  }

  return {
    resolution: FILM_RESOLUTION,
    aspect: FILM_ASPECT,
    targetMinutes: minutes,
    clipSeconds: CLIP_SECONDS,
    clipCount,
    runtimeLabel: `${minutes} min · ${clipCount} × ${CLIP_SECONDS}s · ${FILM_RESOLUTION}`,
    clips,
    handshake:
      "Sim first. If we both like it, we commission the long 4K — clip by clip, together. Nothing generates until then.",
  };
}
