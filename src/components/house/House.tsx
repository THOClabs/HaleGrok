import { useEffect, useMemo, useRef, useState } from "react";
import { Link } from "@tanstack/react-router";
import { HOUSE_FILM, houseTweet } from "@/hale/house-film";
import { xComposeUrl } from "@/hale/x-compose";
import { Button } from "@/components/ui/button";

export function House() {
  const shots = HOUSE_FILM.shots;
  const arrived = useMemo(() => shots.filter((s) => s.file), [shots]);
  const [on, setOn] = useState(0);
  const video = useRef<HTMLVideoElement>(null);
  const current = arrived[on] ?? arrived[0];

  useEffect(() => {
    const el = video.current;
    if (!el || !current?.file) return;
    el.load();
    void el.play().catch(() => undefined);
  }, [current?.file]);

  function next() {
    if (arrived.length < 2) return;
    setOn((i) => (i + 1) % arrived.length);
  }

  if (!current) {
    return (
      <div className="grid min-h-dvh place-items-center bg-house px-6 text-house-fg">
        <p className="font-house text-house-mute">No pictures yet.</p>
      </div>
    );
  }

  return (
    <div className="flex min-h-dvh flex-col bg-house text-house-fg">
      <header className="flex items-center justify-between px-5 py-4 md:px-8">
        <div>
          <p className="font-house text-xs tracking-[0.22em] text-house-mute uppercase">
            HaleGrok House
          </p>
          <h1 className="font-display text-3xl font-medium tracking-tight md:text-4xl">
            {HOUSE_FILM.title}
          </h1>
        </div>
        <div className="flex items-center gap-3">
          <Button
            className="bg-house-mark text-house hover:bg-house-fg"
            onClick={() => window.open(xComposeUrl(houseTweet()), "_blank", "noopener,noreferrer")}
          >
            Post to X
          </Button>
        </div>
      </header>

      <main className="flex flex-1 flex-col px-3 pb-4 md:px-8">
        <div className="overflow-hidden rounded-xl bg-house">
          <video
            ref={video}
            key={current.file}
            className="aspect-video w-full bg-house object-cover"
            src={current.file}
            poster={current.still}
            controls
            playsInline
            onEnded={next}
          />
        </div>

        <div className="mt-5 flex flex-wrap items-end justify-between gap-4">
          <div className="max-w-xl">
            <p className="font-house text-xs tracking-[0.18em] text-house-mute uppercase">
              {current.tStart} · clip {current.index} of {HOUSE_FILM.total}
            </p>
            <h2 className="mt-1 font-display text-2xl">{current.title}</h2>
            <p className="mt-1 text-house-mute">{current.line}</p>
            <p className="mt-2 font-mono text-xs text-house-mute">
              ν {current.nuDeg.toFixed(1)}° · r {current.rKm.toFixed(0)} km · v{" "}
              {current.vKms.toFixed(3)} km/s · Earth {current.earthDeg.toFixed(0)}°
            </p>
          </div>
          <p className="font-house text-sm text-house-mute">
            {HOUSE_FILM.arrived} of {HOUSE_FILM.total} arrived · {HOUSE_FILM.runtime}
          </p>
        </div>

        <ol className="mt-6 grid grid-cols-4 gap-2 md:grid-cols-8">
          {shots.map((s, i) => {
            const live = Boolean(s.file);
            const active = live && arrived[on]?.index === s.index;
            return (
              <li key={s.index}>
                <button
                  type="button"
                  disabled={!live}
                  onClick={() => setOn(arrived.findIndex((a) => a.index === s.index))}
                  className={[
                    "flex min-h-16 w-full flex-col justify-between rounded-md border px-2 py-2 text-left",
                    live ? "border-house-line bg-house-elev" : "border-house-line/50 opacity-40",
                    active ? "border-house-mark" : "",
                  ].join(" ")}
                >
                  <span className="font-mono text-[10px] text-house-mute">{s.tStart}</span>
                  <span className="font-house text-xs leading-tight">
                    {live ? s.title : "—"}
                  </span>
                </button>
              </li>
            );
          })}
        </ol>
      </main>

      <footer className="flex items-center justify-between px-5 py-4 text-xs text-house-mute md:px-8">
        <p>{HOUSE_FILM.logline}</p>
        <Link to="/desk" className="hover:text-house-fg">
          Desk
        </Link>
      </footer>
    </div>
  );
}
