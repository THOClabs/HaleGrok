import { createFileRoute } from "@tanstack/react-router";
import { House } from "@/components/house/House";

export const Route = createFileRoute("/")({
  component: House,
  ssr: false,
});
