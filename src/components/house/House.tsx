import { useEffect, useMemo, useRef, useState } from "react";
import { Link } from "@tanstack/react-router";
import { HOW_FAR, howFarTweet } from "@/hale/how-far";
import { xComposeUrl } from "@/hale/x-compose";
import { Button } from "@/components/ui/button";

const CYCLE_MS = 8000;

export function House() {
  const shots = HOW_FAR.shots;
  const playable = useMemo(
    () => shots.filter((s) => s.file || s.still || s.wire),
    [shots],
  );
  const [on, setOn] = useState(0);
  const [vidOk, setVidOk] = useState(true);
  const video = useRef<HTMLVideoElement>(null);
  const current = playable[on] ?? playable[0];

  useEffect(() => {
    setVidOk(true);
    const el = video.current;
    if (!el || !current?.file) return;
    el.load();
    void el.play().catch(() => undefined);
  }, [current?.file, on]);

  useEffect(() => {
    if (playable.length < 2) return;
    const id = window.setInterval(() => {
      setOn((i) => (i + 1) % playable.length);
    }, CYCLE_MS);
    return () => window.clearInterval(id);
  }, [playable.length]);

  if (!current) {
    return (
      <div className="grid min-h-dvh place-items-center bg-house px-6 text-house-fg">
        <p className="font-house text-house-mute">The next picture is still in the sim.</p>
      </div>
    );
  }

  const showVideo = Boolean(current.file) && vidOk;

  return (
    <div className="flex min-h-dvh flex-col bg-house text-house-fg">
      <header className="flex items-center justify-between px-5 py-4 md:px-8">
        <div>
          <p className="font-house text-xs tracking-[0.22em] text-house-mute uppercase">
            HaleGrok House
          </p>
          <h1 className="font-display text-3xl font-medium tracking-tight md:text-4xl">
            {HOW_FAR.title}
          </h1>
        </div>
        <Button
          className="bg-house-mark text-house hover:bg-house-fg"
          onClick={() => window.open(xComposeUrl(howFarTweet()), "_blank", "noopener,noreferrer")}
        >
          Post to X
        </Button>
      </header>

      <main className="flex flex-1 flex-col px-3 pb-4 md:px-8">
        <div className="overflow-hidden rounded-xl bg-house-elev">
          {showVideo ? (
            <video
              ref={video}
              key={current.file}
              className="aspect-video w-full bg-house object-cover"
              src={current.file}
              poster={current.still ?? current.wire}
              playsInline
              muted
              autoPlay
              onError={() => setVidOk(false)}
            />
          ) : (
            <img
              src={current.still ?? current.wire}
              alt={current.title}
              className="aspect-video w-full bg-house object-cover"
            />
          )}
        </div>

        <div className="mt-5 flex flex-wrap items-end justify-between gap-4">
          <div className="max-w-2xl">
            <p className="font-house text-xs tracking-[0.18em] text-house-mute uppercase">
              {current.tStart} · {current.index} / {HOW_FAR.total} · cycling
            </p>
            <h2 className="mt-1 font-display text-2xl">{current.title}</h2>
            <p className="mt-1 text-house-mute">{current.line}</p>
            <p className="mt-2 font-mono text-xs text-house-mute">{current.finding}</p>
          </div>
          <p className="font-house text-sm text-house-mute">{HOW_FAR.runtime} documentary</p>
        </div>

        <ol className="mt-6 grid grid-cols-4 gap-2 md:grid-cols-8">
          {shots.map((s) => {
            const live = Boolean(s.file || s.still || s.wire);
            const active = current.index === s.index;
            return (
              <li key={s.index}>
                <button
                  type="button"
                  disabled={!live}
                  onClick={() => setOn(playable.findIndex((a) => a.index === s.index))}
                  className={[
                    "flex min-h-20 w-full flex-col overflow-hidden rounded-md border text-left",
                    live ? "border-house-line bg-house-elev" : "border-house-line opacity-40",
                    active ? "border-house-mark" : "",
                  ].join(" ")}
                >
                  <img
                    src={s.still ?? s.wire}
                    alt=""
                    className="h-12 w-full object-cover"
                  />
                  <span className="px-2 py-1 font-house text-xs leading-tight">{s.title}</span>
                </button>
              </li>
            );
          })}
        </ol>
      </main>

      <footer className="flex items-center justify-between px-5 py-4 text-xs text-house-mute md:px-8">
        <p>{HOW_FAR.logline}</p>
        <Link to="/desk" className="hover:text-house-fg">
          Desk
        </Link>
      </footer>
    </div>
  );
}
