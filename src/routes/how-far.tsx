import { createFileRoute } from "@tanstack/react-router";
import { House } from "@/components/house/House";

export const Route = createFileRoute("/how-far")({
  component: House,
  ssr: false,
});
