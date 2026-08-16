import { useState } from "react";
import { CLIMB_OPENING } from "@/hale/climb-reel";
import { cn } from "@/lib/utils";

export function FilmReel({ productionId }: { productionId: number }) {
  const shots = productionId === 1 ? CLIMB_OPENING : [];
  const [on, setOn] = useState(0);
  if (!shots.length) return null;
  const shot = shots[on]!;

  return (
    <section className="border-t border-line">
      <div className="flex items-baseline justify-between px-5 py-3">
        <div>
          <p className="font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
            The Climb · opening reel
          </p>
          <h3 className="text-lg font-medium">
            Clip {shot.index} of 48 · {shot.tStart}
          </h3>
        </div>
        <p className="font-mono text-[11px] text-accent">{shot.finding}</p>
      </div>
      <video
        key={shot.file}
        className="aspect-video w-full bg-black object-cover"
        src={shot.file}
        poster={shot.still}
        controls
        playsInline
        autoPlay
        muted
      />
      <div className="grid grid-cols-2 gap-px bg-line">
        {shots.map((s, i) => (
          <button
            key={s.index}
            type="button"
            onClick={() => setOn(i)}
            className={cn(
              "flex items-center gap-3 bg-surface px-4 py-3 text-left",
              i === on && "bg-raised",
            )}
          >
            <img src={s.still} alt="" className="h-12 w-20 object-cover" />
            <div>
              <div className="text-sm font-medium">{s.title}</div>
              <div className="font-mono text-[11px] text-muted">
                {s.tStart} · {s.finding}
              </div>
            </div>
          </button>
        ))}
      </div>
    </section>
  );
}
