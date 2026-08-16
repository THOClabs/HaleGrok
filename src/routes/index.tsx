import { createFileRoute } from "@tanstack/react-router";
import { Review } from "@/components/review/Review";

export const Route = createFileRoute("/")({
  component: Review,
  ssr: false,
});
