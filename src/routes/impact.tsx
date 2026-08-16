import { createFileRoute } from "@tanstack/react-router";
import { ImpactFilm } from "@/components/house/ImpactFilm";

export const Route = createFileRoute("/impact")({
  validateSearch: (s: Record<string, unknown>) => ({
    t: Number(s.t ?? 0) || 0,
  }),
  component: function ImpactPage() {
    const { t } = Route.useSearch();
    return (
      <div className="h-dvh w-screen overflow-hidden bg-house">
        <ImpactFilm startAt={t} />
      </div>
    );
  },
  ssr: false,
});
