import { createFileRoute } from "@tanstack/react-router";
import { TrojanFilm } from "@/components/house/TrojanFilm";

export const Route = createFileRoute("/film/ep01")({
  validateSearch: (s: Record<string, unknown>) => ({
    t: Number(s.t ?? 0) || 0,
  }),
  component: function FilmEp01() {
    const { t } = Route.useSearch();
    return (
      <div className="grid h-dvh w-screen place-items-center bg-house">
        <div className="w-full max-w-[100vw]">
          <TrojanFilm startAt={t} />
        </div>
      </div>
    );
  },
  ssr: false,
});
