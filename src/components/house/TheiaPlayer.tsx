import { useEffect, useRef, useState } from "react";
import { EP01, EP01_SHOTS } from "@/hale/theia/ep01-film";
import { EP02, EP02_SHOTS } from "@/hale/theia/ep02-film";

const FILMS = [
  {
    id: "ep01",
    title: EP01.title,
    master: "/films/003/the-trojan-twin-4k.mp4",
    shots: EP01_SHOTS,
    delivery: EP01.delivery,
  },
  {
    id: "ep02",
    title: EP02.title,
    master: "/films/004/ten-percent-4k.mp4",
    shots: EP02_SHOTS,
    delivery: EP02.delivery,
  },
] as const;

export function TheiaPlayer({ initial = 1 }: { initial?: number }) {
  const video = useRef<HTMLVideoElement>(null);
  const [filmI, setFilmI] = useState(initial);
  const [on, setOn] = useState(0);
  const film = FILMS[filmI]!;

  useEffect(() => {
    const el = video.current;
    if (!el) return;
    el.load();
    void el.play().catch(() => undefined);
    setOn(0);
  }, [filmI]);

  return (
    <div>
      <div className="relative overflow-hidden rounded-xl bg-house">
        <video
          ref={video}
          className="aspect-video w-full bg-house object-cover"
          src={film.master}
          poster={film.shots[0]?.still}
          muted
          playsInline
          autoPlay
          onEnded={() => {
            const el = video.current;
            if (!el) return;
            el.currentTime = 0;
            void el.play().catch(() => undefined);
          }}
          onTimeUpdate={() => {
            const el = video.current;
            if (!el) return;
            setOn(Math.min(7, Math.floor(el.currentTime / 15)));
          }}
        />
        <div className="pointer-events-none absolute inset-x-0 bottom-0 px-5 pb-4 pt-16">
          <p className="font-house text-xs tracking-[0.18em] text-house-mute uppercase">
            {film.shots[on]?.tStart} · {film.shots[on]?.title} · {film.delivery}
          </p>
          <p className="font-mono text-xs text-house-mute">{film.shots[on]?.finding}</p>
        </div>
      </div>
      <div className="mt-3 flex gap-2">
        {FILMS.map((f, i) => (
          <button
            key={f.id}
            type="button"
            onClick={() => setFilmI(i)}
            className={[
              "min-h-11 rounded-md border px-3 py-2 text-sm",
              i === filmI ? "border-house-mark bg-house-elev text-house-fg" : "border-house-line text-house-mute",
            ].join(" ")}
          >
            {String(i + 1).padStart(2, "0")} {f.title}
          </button>
        ))}
      </div>
    </div>
  );
}
