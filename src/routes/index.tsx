import { createFileRoute } from "@tanstack/react-router";
import { StudioDesk } from "@/components/desk/StudioDesk";

export const Route = createFileRoute("/")({
  component: StudioDesk,
  ssr: false,
});
