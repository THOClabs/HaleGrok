import { SPLASH_FILMS } from "@/hale/theia/posts";
import { xComposeUrl } from "@/hale/x-compose";
import { Button } from "@/components/ui/button";

export function Splash() {
  return (
    <ol className="mx-auto flex max-w-3xl flex-col gap-8 bg-house px-4 py-8 text-house-fg md:px-6">
      {SPLASH_FILMS.map((film) => (
        <li key={film.n} className="flex flex-col gap-3">
          <video
            className="aspect-video w-full rounded-md bg-house-elev object-cover"
            src={film.master}
            poster={film.poster}
            controls
            playsInline
            preload="metadata"
          />
          <div className="flex items-center justify-between gap-3">
            <p className="min-w-0 text-sm text-house-fg">{film.tweet}</p>
            <Button
              className="shrink-0 bg-house-mark text-house hover:bg-house-fg"
              onClick={() => window.open(xComposeUrl(film.tweet), "_blank", "noopener,noreferrer")}
            >
              Post to X
            </Button>
          </div>
        </li>
      ))}
    </ol>
  );
}
