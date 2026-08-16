import { createFileRoute } from "@tanstack/react-router";
import { TenPercentFilm } from "@/components/house/TenPercentFilm";

export const Route = createFileRoute("/film/ep02")({
  validateSearch: (s: Record<string, unknown>) => ({
    t: Number(s.t ?? 0) || 0,
  }),
  component: function FilmEp02() {
    const { t } = Route.useSearch();
    return (
      <div className="grid h-dvh w-screen place-items-center bg-house">
        <div className="w-full max-w-[100vw]">
          <TenPercentFilm startAt={t} />
        </div>
      </div>
    );
  },
  ssr: false,
});
