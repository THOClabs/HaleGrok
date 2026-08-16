import { useEffect, useState } from "react";
import { Link } from "@tanstack/react-router";
import { runTheiaSeries, type EpisodeResult } from "@/hale/theia/series";
import { xComposeUrl } from "@/hale/x-compose";
import { Button } from "@/components/ui/button";
import { GATE_ORDER } from "@/hale/types";
import { TheiaPlayer } from "@/components/house/TheiaPlayer";
import { HaleStage } from "@/components/house/HaleStage";
import { SERIES_FILMS } from "@/hale/theia/films";

const RESULTS: EpisodeResult[] = runTheiaSeries();

function tweet(): string {
  return [
    `Theia / Terra — 12 × 2:00 4K.`,
    `L4 to Luna. Hale all the way.`,
    `#HaleGrok`,
  ].join("\n");
}

export function TheiaSeries() {
  const [on, setOn] = useState(11);
  const current = RESULTS[on]!;

  useEffect(() => {
    const id = window.setInterval(() => setOn((i) => (i + 1) % RESULTS.length), 7000);
    return () => window.clearInterval(id);
  }, []);

  const passed = RESULTS.filter((r) => r.passed).length;

  return (
    <div className="flex min-h-dvh flex-col bg-house text-house-fg">
      <header className="flex flex-wrap items-center justify-between gap-4 px-5 py-4 md:px-8">
        <div>
          <p className="font-house text-xs tracking-[0.22em] text-house-mute uppercase">
            HaleGrok House · series
          </p>
          <h1 className="font-display text-3xl font-medium tracking-tight md:text-4xl">
            Theia / Terra
          </h1>
          <p className="mt-1 text-sm text-house-mute">
            {passed}/12 gauntlets · twelve 4K cuts · Theia to Luna
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Link to="/how-far" className="text-sm text-house-mute hover:text-house-fg">
            How Far
          </Link>
          <Button
            className="bg-house-mark text-house hover:bg-house-fg"
            onClick={() => window.open(xComposeUrl(tweet()), "_blank", "noopener,noreferrer")}
          >
            Post to X
          </Button>
        </div>
      </header>

      <main className="flex flex-1 flex-col gap-6 px-3 pb-6 md:px-8">
        <TheiaPlayer />
        <details className="rounded-xl border border-house-line px-4 py-3">
          <summary className="cursor-pointer font-house text-sm text-house-mute">
            Live Hale instrument — same L4 numbers
          </summary>
          <div className="mt-3">
            <HaleStage film={SERIES_FILMS[0]!} />
          </div>
        </details>

        <ol className="grid grid-cols-2 gap-2 md:grid-cols-4 xl:grid-cols-6">
          {RESULTS.map((r, i) => (
            <li key={r.spec.id}>
              <button
                type="button"
                onClick={() => setOn(i)}
                className={[
                  "flex min-h-28 w-full flex-col justify-between rounded-md border px-3 py-3 text-left",
                  i === on ? "border-house-mark bg-house-elev" : "border-house-line bg-house",
                ].join(" ")}
              >
                <span className="font-mono text-[10px] text-house-mute">
                  {String(r.spec.n).padStart(2, "0")} · {r.passed ? "PASS" : "HOLD"}
                </span>
                <span className="font-display text-lg leading-tight">{r.spec.title}</span>
                <span className="font-mono text-[10px] text-house-mute">
                  {r.findings[0]}
                </span>
              </button>
            </li>
          ))}
        </ol>

        <section className="grid gap-6 lg:grid-cols-[1.2fr_1fr]">
          <div className="rounded-xl border border-house-line bg-house-elev px-5 py-5">
            <p className="font-house text-xs tracking-[0.18em] text-house-mute uppercase">
              Episode {String(current.spec.n).padStart(2, "0")} · {current.spec.perspective}
            </p>
            <h2 className="mt-1 font-display text-3xl">{current.spec.title}</h2>
            <p className="mt-2 text-house-mute">{current.spec.logline}</p>
            <p className="mt-2 font-mono text-xs text-house-mute">{current.spec.haleRef}</p>

            <ol className="mt-5 space-y-2">
              {current.beats.map((b) => (
                <li key={b.t} className="flex gap-3 text-sm">
                  <span className="w-10 font-mono text-house-mute">{b.t}</span>
                  <span>
                    {b.shot}
                    <span className="mt-0.5 block font-mono text-[11px] text-house-mute">
                      {b.fromFinding}
                    </span>
                  </span>
                </li>
              ))}
            </ol>
          </div>

          <div className="rounded-xl border border-house-line px-5 py-5">
            <h3 className="font-house text-xs tracking-[0.18em] text-house-mute uppercase">
              Gauntlet
            </h3>
            <ul className="mt-3 space-y-1">
              {GATE_ORDER.map((id) => {
                const g = current.gates.find((x) => x.id === id);
                return (
                  <li key={id} className="flex gap-3 font-mono text-xs">
                    <span className="w-16 text-house-mute">{id}</span>
                    <span>{g?.status ?? "—"}</span>
                    <span className="text-house-mute">{g?.detail}</span>
                  </li>
                );
              })}
            </ul>
            <h3 className="mt-6 font-house text-xs tracking-[0.18em] text-house-mute uppercase">
              Ada / Hale steps
            </h3>
            <ul className="mt-3 space-y-2">
              {current.steps.map((s) => (
                <li key={s.name} className="text-sm">
                  <span className={s.ok ? "text-pass" : "text-fail"}>{s.name}</span>
                  <span className="mt-0.5 block font-mono text-[11px] text-house-mute">
                    {s.source} · {s.detail}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        </section>
      </main>

      <footer className="flex items-center justify-between px-5 py-4 text-xs text-house-mute md:px-8">
        <p>Sims first. Pictures after. Nothing less than two minutes.</p>
        <Link to="/desk" className="hover:text-house-fg">
          Desk
        </Link>
      </footer>
    </div>
  );
}
