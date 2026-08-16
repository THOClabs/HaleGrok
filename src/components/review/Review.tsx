import { shortlist, runReviewGauntlet } from "@/hale/review/gauntlet";
import { xComposeUrl } from "@/hale/x-compose";
import { Button } from "@/components/ui/button";

const kept = shortlist();
const tally = runReviewGauntlet();

export function Review() {
  return (
    <div className="min-h-dvh bg-house text-house-fg">
      <header className="mx-auto flex max-w-4xl items-end justify-between px-4 pb-6 pt-8 md:px-6">
        <div>
          <p className="font-house text-xs tracking-[0.22em] text-house-mute uppercase">
            Review
          </p>
          <h1 className="font-display text-3xl font-medium tracking-tight">
            Cut for X
          </h1>
        </div>
        <p className="font-mono text-xs text-house-mute">
          {tally.kept} passed · {tally.killed} killed
        </p>
      </header>

      <ol className="mx-auto flex max-w-4xl flex-col gap-12 px-4 pb-16 md:px-6">
        {kept.map((r) => (
          <li key={r.item.id} className="flex flex-col gap-3">
            {r.item.kind === "video" ? (
              <video
                className="aspect-video w-full rounded-md bg-house-elev object-cover"
                src={r.item.src}
                poster={r.item.poster}
                controls
                playsInline
                preload="metadata"
              />
            ) : (
              <img
                src={r.item.src}
                alt={r.item.title}
                className="aspect-video w-full rounded-md bg-house-elev object-cover"
              />
            )}
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div className="min-w-0">
                <p className="font-mono text-xs text-house-mute">
                  {r.mean.toFixed(1)} · {r.item.kind} · {r.item.title}
                </p>
                <p className="mt-1 text-sm text-house-fg">{r.item.tweet}</p>
              </div>
              <Button
                className="min-h-11 shrink-0 bg-house-mark text-house hover:bg-house-fg"
                onClick={() => window.open(xComposeUrl(r.item.tweet), "_blank", "noopener,noreferrer")}
              >
                Post to X
              </Button>
            </div>
          </li>
        ))}
      </ol>
    </div>
  );
}
