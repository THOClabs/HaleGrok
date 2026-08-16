import { createFileRoute } from "@tanstack/react-router";
import { TheiaSeries } from "@/components/house/TheiaSeries";

export const Route = createFileRoute("/series")({
  component: TheiaSeries,
  ssr: false,
});
