import { createFileRoute } from "@tanstack/react-router";
import { HaleStage } from "@/components/house/HaleStage";
import { filmBySlug } from "@/hale/theia/films";

export const Route = createFileRoute("/film/$slug")({
  validateSearch: (s: Record<string, unknown>) => ({
    t: Number(s.t ?? 0) || 0,
  }),
  component: function FilmSlug() {
    const { slug } = Route.useParams();
    const { t } = Route.useSearch();
    const film = filmBySlug(slug);
    if (!film) {
      return (
        <div className="grid min-h-dvh place-items-center bg-house text-house-mute">
          No film.
        </div>
      );
    }
    return (
      <div className="grid h-dvh w-screen place-items-center bg-house">
        <div className="w-full max-w-[100vw]">
          <HaleStage film={film} startAt={t} />
        </div>
      </div>
    );
  },
  ssr: false,
});
