import { createFileRoute } from "@tanstack/react-router";
import { StudioDesk } from "@/components/desk/StudioDesk";

export const Route = createFileRoute("/desk")({
  component: StudioDesk,
  ssr: false,
});
